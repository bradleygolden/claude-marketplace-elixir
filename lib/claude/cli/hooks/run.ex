defmodule Claude.CLI.Hooks.Run do
  @moduledoc """
  Handles dynamic hook execution.
  This is called by Claude Code hooks, not directly by users.

  Usage:
    mix claude hooks run <hook_identifier>

  The hook receives the full Claude Code JSON via stdin.

  Example:
    echo '{"session_id": "123", "event": {...}}' | mix claude hooks run post_tool_use.elixir_formatter
  """

  alias Claude.Hooks
  alias Claude.Hooks.Telemetry

  def run([hook_identifier]) do
    input = IO.read(:stdio, :eof)

    # Handle empty stdin case
    input = if input == :eof, do: "", else: input

    case Hooks.find_hook_by_identifier(hook_identifier) do
      nil ->
        :ok

      hook_module ->
        # Get user config if available
        user_config = get_user_config(hook_identifier)

        # Create a function that calls the hook with the right arity
        hook_fn = fn ->
          if function_exported?(hook_module, :run, 2) do
            hook_module.run(input, user_config)
          else
            hook_module.run(input)
          end
        end

        # Use telemetry if available, otherwise run directly
        if Telemetry.telemetry_available?() do
          Telemetry.execute_hook_fn(hook_fn, hook_module, input)
        else
          hook_fn.()
        end
    end
  end

  def run(_args) do
    :ok
  end

  defp get_user_config(hook_identifier) do
    # Find the hook configuration from registry
    case Enum.find(Hooks.all_hooks(), fn {module, _config} ->
           Hooks.hook_identifier(module) == hook_identifier
         end) do
      {_module, config} -> config
      _ -> %{}
    end
  end
end
