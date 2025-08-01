defmodule Claude.Hooks.JsonOutput do
  @moduledoc """
  Helper module for creating JSON output from hooks according to Claude Code's specification.

  Provides structured JSON output instead of relying on exit codes, giving hooks
  more sophisticated control over Claude Code's behavior.
  """

  @derive Jason.Encoder
  defstruct [
    :continue,
    :stopReason,
    :suppressOutput,
    :decision,
    :reason,
    :hookSpecificOutput
  ]

  @type t :: %__MODULE__{
          continue: boolean() | nil,
          stopReason: String.t() | nil,
          suppressOutput: boolean() | nil,
          decision: String.t() | nil,
          reason: String.t() | nil,
          hookSpecificOutput: map() | nil
        }

  @doc """
  Creates a success output that allows Claude to continue normally.

  Options:
    - :suppress_output - Hide stdout from transcript mode (default: false)
  """
  def success(opts \\ []) do
    %__MODULE__{
      continue: true,
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates an output that stops Claude from continuing.

  The stop_reason is shown to the user (not Claude).
  """
  def stop(stop_reason, opts \\ []) do
    %__MODULE__{
      continue: false,
      stopReason: stop_reason,
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates a blocking decision output for PostToolUse hooks.

  The reason is shown to Claude for automatic processing.
  """
  def block_post_tool(reason, opts \\ []) do
    %__MODULE__{
      decision: "block",
      reason: reason,
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates a deny decision output for PreToolUse hooks.

  The reason is shown to Claude for automatic processing.
  """
  def deny_pre_tool(reason, opts \\ []) do
    %__MODULE__{
      hookSpecificOutput: %{
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: reason
      },
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates an allow decision output for PreToolUse hooks.

  Bypasses the permission system. The reason is shown to the user but not Claude.
  """
  def allow_pre_tool(reason \\ nil, opts \\ []) do
    output = %{
      hookEventName: "PreToolUse",
      permissionDecision: "allow"
    }

    output = if reason, do: Map.put(output, :permissionDecisionReason, reason), else: output

    %__MODULE__{
      hookSpecificOutput: output,
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates an ask decision output for PreToolUse hooks.

  Asks the user to confirm the tool call. The reason is shown to the user but not Claude.
  """
  def ask_pre_tool(reason, opts \\ []) do
    %__MODULE__{
      hookSpecificOutput: %{
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: reason
      },
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates a block decision output for UserPromptSubmit hooks.

  Prevents the prompt from being processed. The reason is shown to the user but not Claude.
  """
  def block_prompt(reason, opts \\ []) do
    %__MODULE__{
      decision: "block",
      reason: reason,
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates an output with additional context for UserPromptSubmit hooks.

  The additional context is added to Claude's context if the prompt is not blocked.
  """
  def add_context(context, opts \\ []) do
    %__MODULE__{
      hookSpecificOutput: %{
        hookEventName: "UserPromptSubmit",
        additionalContext: context
      },
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Creates a block decision output for Stop/SubagentStop hooks.

  Prevents Claude from stopping. The reason must be provided for Claude to know how to proceed.
  """
  def block_stop(reason, opts \\ []) do
    %__MODULE__{
      decision: "block",
      reason: reason,
      suppressOutput: Keyword.get(opts, :suppress_output, false)
    }
  end

  @doc """
  Outputs the JSON to stdout and exits with code 0.

  According to Claude Code docs, JSON output should be written to stdout with exit code 0.

  In test environment with mocked System module, returns :ok instead of halting.
  """
  def write_and_exit(%__MODULE__{} = output) do
    output
    |> clean_nil_values()
    |> Jason.encode!()
    |> IO.puts()

    # When System is mocked (in tests), halt returns a value instead of actually halting
    case System.halt(0) do
      {:halt, 0} -> :ok
      _ -> :ok
    end
  end

  @doc """
  Converts the output to JSON string without exiting.

  Useful for testing or when you need to manipulate the JSON before outputting.
  """
  def to_json(%__MODULE__{} = output) do
    output
    |> clean_nil_values()
    |> Jason.encode!()
  end

  # Remove nil values from the struct to keep JSON clean
  defp clean_nil_values(%__MODULE__{} = output) do
    output
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
