defmodule Claude.Hooks.Telemetry.DefaultHandler do
  @moduledoc """
  Default telemetry handlers for Claude hooks.

  This module requires the `:telemetry` dependency to be available. If telemetry
  is not installed, all functions will return appropriate defaults.

  This module provides optional telemetry handlers that log hook execution events.
  These handlers are designed to work out-of-the-box for common debugging and
  monitoring scenarios.

  ## Usage

  To attach the default handlers, call `attach_default_handlers/0` in your application:

      Claude.Hooks.Telemetry.DefaultHandler.attach_default_handlers()

  This will attach handlers for:
  - Hook start events (logged at debug level)
  - Hook completion events (logged at debug level with duration)
  - Hook exception events (logged at error level with error details)

  ## Configuration

  The handlers respect the standard Logger configuration. You can control the
  verbosity by setting the Logger level:

      config :logger, level: :info  # Will not show debug logs
      config :logger, level: :debug # Will show all hook execution logs

  ## Custom Handlers

  If you need different behavior, you can attach your own handlers instead:

      :telemetry.attach(
        "my-hook-handler",
        [:claude, :hook, :stop],
        &MyApp.handle_hook_event/4,
        nil
      )
  """

  require Logger
  alias Claude.Hooks.Telemetry

  @handler_prefix "claude-hooks-default"

  @doc """
  Attaches default telemetry handlers for Claude hooks.

  This function is idempotent - calling it multiple times will not create
  duplicate handlers.

  ## Returns

  - `:ok` if handlers were successfully attached
  - `{:error, :already_attached}` if handlers are already attached
  """
  @spec attach_default_handlers() ::
          :ok | {:error, :already_attached} | {:error, :telemetry_not_available}
  def attach_default_handlers do
    if Telemetry.telemetry_available?() do
      handlers = [
        {[:claude, :hook, :start], &handle_start/4, "start"},
        {[:claude, :hook, :stop], &handle_stop/4, "stop"},
        {[:claude, :hook, :exception], &handle_exception/4, "exception"}
      ]

      results =
        for {event, handler, suffix} <- handlers do
          handler_id = "#{@handler_prefix}-#{suffix}"

          case apply(:telemetry, :attach, [handler_id, event, handler, nil]) do
            :ok -> :ok
            {:error, :already_exists} -> :already_exists
          end
        end

      if Enum.all?(results, &(&1 == :already_exists)) do
        {:error, :already_attached}
      else
        :ok
      end
    else
      {:error, :telemetry_not_available}
    end
  end

  @doc """
  Detaches all default telemetry handlers.

  ## Returns

  - `:ok` - Always returns ok, even if handlers were not attached
  """
  @spec detach_default_handlers() :: :ok
  def detach_default_handlers do
    if Telemetry.telemetry_available?() do
      for suffix <- ["start", "stop", "exception"] do
        handler_id = "#{@handler_prefix}-#{suffix}"
        apply(:telemetry, :detach, [handler_id])
      end
    end

    :ok
  end

  @doc """
  Checks if default handlers are currently attached.

  ## Returns

  - `true` if all default handlers are attached
  - `false` if any handler is not attached
  """
  @spec handlers_attached?() :: boolean()
  def handlers_attached? do
    if Telemetry.telemetry_available?() do
      handler_ids =
        for suffix <- ["start", "stop", "exception"] do
          "#{@handler_prefix}-#{suffix}"
        end

      attached_ids =
        apply(:telemetry, :list_handlers, [[:claude, :hook, :start]]) ++
          apply(:telemetry, :list_handlers, [[:claude, :hook, :stop]]) ++
          apply(:telemetry, :list_handlers, [[:claude, :hook, :exception]])

      attached_ids = Enum.map(attached_ids, & &1.id)

      Enum.all?(handler_ids, &(&1 in attached_ids))
    else
      false
    end
  end

  # Private handler functions

  defp handle_start(_event, _measurements, metadata, _config) do
    message =
      "Hook starting - " <>
        "hook: #{metadata.hook_identifier}, " <>
        "event: #{inspect(metadata.hook_event)}, " <>
        "tool: #{inspect(metadata[:tool_name])}, " <>
        "session: #{inspect(metadata[:session_id])}, " <>
        "input_size: #{metadata.input_size}"

    Logger.debug(message)
  end

  defp handle_stop(_event, measurements, metadata, _config) do
    duration_ms = Float.round(measurements.duration / 1_000_000, 2)

    message =
      "Hook completed - " <>
        "hook: #{metadata.hook_identifier}, " <>
        "event: #{inspect(metadata.hook_event)}, " <>
        "tool: #{inspect(metadata[:tool_name])}, " <>
        "session: #{inspect(metadata[:session_id])}, " <>
        "duration_ms: #{duration_ms}, " <>
        "result: #{inspect(metadata.result)}"

    Logger.debug(message)
  end

  defp handle_exception(_event, measurements, metadata, _config) do
    duration_ms = Float.round(measurements.duration / 1_000_000, 2)

    message =
      "Hook failed - " <>
        "hook: #{metadata.hook_identifier}, " <>
        "event: #{inspect(metadata.hook_event)}, " <>
        "tool: #{inspect(metadata[:tool_name])}, " <>
        "session: #{inspect(metadata[:session_id])}, " <>
        "duration_ms: #{duration_ms}, " <>
        "error: #{Exception.format(metadata.kind, metadata.reason, metadata.stacktrace)}"

    Logger.error(message)
  end
end
