defmodule Claude.Hooks.Telemetry do
  @moduledoc """
  Telemetry integration for Claude hooks.

  This module provides automatic telemetry instrumentation for all hook executions,
  enabling users to monitor and measure hook performance and behavior.

  ## Requirements

  Telemetry is an optional dependency. To use telemetry features, add it to your
  project's dependencies:

      defp deps do
        [
          {:claude, "~> 0.1"},
          {:telemetry, "~> 1.2"}
        ]
      end

  If telemetry is not available, hooks will execute normally without any
  instrumentation.

  ## Telemetry Events

  The following events are emitted when telemetry is available:

  - `[:claude, :hook, :start]` - When a hook starts executing
  - `[:claude, :hook, :stop]` - When a hook completes successfully  
  - `[:claude, :hook, :exception]` - When a hook raises an exception

  ## Measurements

  - `:duration` - The time in native units spent executing the hook (stop/exception events)
  - `:input_size` - Size of the JSON input in bytes (start event)

  ## Metadata

  All events include the following metadata:

  ### Core Metadata (always present)
  - `:hook_module` - The hook module being executed
  - `:hook_identifier` - The hook identifier (e.g., "post_tool_use.elixir_formatter")
  - `:hook_event` - The hook event type (e.g., :post_tool_use, :pre_tool_use)
  - `:input_size` - Size of the JSON input in bytes

  ### Common Hook Input Fields (when present in input)
  - `:session_id` - The Claude Code session ID
  - `:transcript_path` - Path to the conversation JSONL file
  - `:cwd` - Current working directory when hook was invoked
  - `:claude_event_name` - The hook_event_name from Claude Code (e.g., "PostToolUse")

  ### Tool-Related Fields (for PreToolUse/PostToolUse events)
  - `:tool_name` - The tool that triggered the hook (e.g., "Write", "Edit")
  - `:tool_input` - The tool input parameters
  - `:tool_response` - The tool response (PostToolUse only)

  ### Event-Specific Fields
  - `:message` - Notification message (Notification event)
  - `:prompt` - User prompt text (UserPromptSubmit event)
  - `:stop_hook_active` - Whether stop hook is already active (Stop/SubagentStop events)
  - `:trigger` - Compact trigger type: "manual" or "auto" (PreCompact event)
  - `:custom_instructions` - Custom instructions for compact (PreCompact event)

  ### Additional Event Metadata
  Stop events also include:
  - `:result` - The return value from the hook execution

  Exception events also include:
  - `:kind` - The kind of exception (:error, :exit, :throw)
  - `:reason` - The exception/exit reason
  - `:stacktrace` - The stacktrace

  ## Usage

  This module is automatically used by the Claude hook system. Hooks are instrumented
  transparently when executed through the hook scripts.

  To attach your own handlers:

      :telemetry.attach(
        "my-handler",
        [:claude, :hook, :stop],
        &MyApp.handle_event/4,
        nil
      )
  """

  alias Claude.Hooks

  @doc """
  Checks if telemetry is available in the current project.
  """
  @spec telemetry_available?() :: boolean()
  def telemetry_available? do
    Code.ensure_loaded?(:telemetry)
  end

  @doc """
  Executes a hook with telemetry instrumentation if available.

  This function wraps hook execution with telemetry events when telemetry is available,
  providing automatic performance monitoring and error tracking. If telemetry is not
  available, the hook is executed normally without instrumentation.

  ## Parameters

  - `hook_module` - The hook module to execute
  - `json_input` - The JSON input string from Claude Code
  - `user_config` - Optional user configuration map (default: %{})

  ## Returns

  Returns the result of the hook execution, or raises if the hook raises.
  """
  @spec execute_hook(module(), String.t(), map()) :: :ok | {:error, term()}
  def execute_hook(hook_module, json_input, user_config \\ %{}) do
    if telemetry_available?() do
      execute_with_telemetry(hook_module, json_input, user_config)
    else
      execute_without_telemetry(hook_module, json_input, user_config)
    end
  end

  @doc """
  Executes a hook function with telemetry instrumentation if available.

  This function wraps hook execution with telemetry events when telemetry is available,
  providing automatic performance monitoring and error tracking. If telemetry is not
  available, the hook is executed normally without instrumentation.

  ## Parameters

  - `hook_fn` - The hook function to execute (arity 0)
  - `hook_module` - The hook module for metadata purposes
  - `json_input` - The JSON input string from Claude Code (for metadata extraction)

  ## Returns

  Returns the result of the hook execution, or raises if the hook raises.
  """
  @spec execute_hook_fn((-> any()), module(), String.t()) :: any()
  def execute_hook_fn(hook_fn, hook_module, json_input) when is_function(hook_fn, 0) do
    if telemetry_available?() do
      execute_fn_with_telemetry(hook_fn, hook_module, json_input)
    else
      hook_fn.()
    end
  end

  defp execute_with_telemetry(hook_module, json_input, user_config) do
    metadata = build_metadata(hook_module, json_input)

    apply(:telemetry, :span, [
      [:claude, :hook],
      metadata,
      fn ->
        result = run_hook(hook_module, json_input, user_config)
        {result, Map.put(metadata, :result, result)}
      end
    ])
  end

  defp execute_without_telemetry(hook_module, json_input, user_config) do
    run_hook(hook_module, json_input, user_config)
  end

  defp execute_fn_with_telemetry(hook_fn, hook_module, json_input) do
    metadata = build_metadata(hook_module, json_input)

    apply(:telemetry, :span, [
      [:claude, :hook],
      metadata,
      fn ->
        result = hook_fn.()
        {result, Map.put(metadata, :result, result)}
      end
    ])
  end

  defp run_hook(hook_module, json_input, user_config) do
    if function_exported?(hook_module, :run, 2) do
      hook_module.run(json_input, user_config)
    else
      hook_module.run(json_input)
    end
  end

  @doc """
  Builds telemetry metadata for a hook execution.

  Extracts relevant information from the hook module and JSON input to provide
  rich context for telemetry events.
  """
  @spec build_metadata(module(), String.t()) :: map()
  def build_metadata(hook_module, json_input) when is_binary(json_input) do
    base_metadata = %{
      hook_module: hook_module,
      hook_identifier: Hooks.hook_identifier(hook_module),
      hook_event: get_hook_event(hook_module),
      input_size: byte_size(json_input)
    }

    case Jason.decode(json_input) do
      {:ok, data} when is_map(data) ->
        base_metadata
        |> maybe_add_field(data, "session_id", :session_id)
        |> maybe_add_field(data, "transcript_path", :transcript_path)
        |> maybe_add_field(data, "cwd", :cwd)
        |> maybe_add_field(data, "hook_event_name", :claude_event_name)
        |> maybe_add_field(data, "tool_name", :tool_name)
        |> maybe_add_field(data, "tool_input", :tool_input)
        |> maybe_add_field(data, "tool_response", :tool_response)
        |> maybe_add_field(data, "message", :message)
        |> maybe_add_field(data, "prompt", :prompt)
        |> maybe_add_field(data, "stop_hook_active", :stop_hook_active)
        |> maybe_add_field(data, "trigger", :trigger)
        |> maybe_add_field(data, "custom_instructions", :custom_instructions)

      _ ->
        base_metadata
    end
  end

  defp maybe_add_field(metadata, data, key, metadata_key) do
    case Map.get(data, key) do
      nil -> metadata
      value -> Map.put(metadata, metadata_key, value)
    end
  end

  defp get_hook_event(hook_module) do
    cond do
      function_exported?(hook_module, :__hook_event__, 0) ->
        hook_module.__hook_event__()

      match?({:module, _}, Code.ensure_compiled(hook_module)) ->
        result =
          hook_module
          |> Module.split()
          |> Enum.find_value(fn
            "PreToolUse" -> :pre_tool_use
            "PostToolUse" -> :post_tool_use
            "UserPromptSubmit" -> :user_prompt_submit
            "Notification" -> :notification
            "Stop" -> :stop
            "SubagentStop" -> :subagent_stop
            "PreCompact" -> :pre_compact
            _ -> nil
          end)

        result || :unknown

      true ->
        :unknown
    end
  end

  @doc """
  Emits a custom telemetry event from within a hook if telemetry is available.

  This is a convenience function for hooks to emit their own domain-specific
  telemetry events while maintaining consistent metadata. If telemetry is not
  available, this function is a no-op.

  ## Parameters

  - `event_suffix` - Atom or list of atoms to append to [:claude, :hook]
  - `measurements` - Map of measurement data
  - `metadata` - Additional metadata to merge with base hook metadata
  - `hook_module` - The hook module emitting the event

  ## Examples

      # From within a hook:
      Claude.Hooks.Telemetry.emit_event(
        [:format, :check],
        %{file_count: 3},
        %{status: :needs_formatting},
        __MODULE__
      )
      
  This would emit the event `[:claude, :hook, :format, :check]` if telemetry is available.
  """
  @spec emit_event(atom() | [atom()], map(), map(), module()) :: :ok
  def emit_event(event_suffix, measurements, metadata, hook_module) do
    if telemetry_available?() do
      emit_telemetry_event(event_suffix, measurements, metadata, hook_module)
    else
      :ok
    end
  end

  defp emit_telemetry_event(event_suffix, measurements, metadata, hook_module) do
    event_suffix_list = List.wrap(event_suffix)
    event = [:claude, :hook] ++ event_suffix_list

    base_metadata = %{
      hook_module: hook_module,
      hook_identifier: Hooks.hook_identifier(hook_module),
      hook_event: get_hook_event(hook_module)
    }

    apply(:telemetry, :execute, [
      event,
      measurements,
      Map.merge(base_metadata, metadata)
    ])
  end
end
