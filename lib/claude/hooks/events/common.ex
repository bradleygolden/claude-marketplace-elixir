defmodule Claude.Hooks.Events.Common do
  @moduledoc """
  Common functionality shared across all hook events.
  """

  alias Claude.Hooks.Events.{
    PreToolUse,
    PostToolUse,
    Notification,
    UserPromptSubmit,
    Stop,
    SubagentStop,
    PreCompact
  }

  @doc """
  Parses a JSON input into the appropriate hook event struct based on hook_event_name.

  ## Examples

      iex> json = ~s({"hook_event_name": "PreToolUse", "tool_name": "Edit", "session_id": "123"})
      iex> {:ok, event} = Claude.Hooks.Events.Common.parse_hook_input(json)
      iex> match?(%Claude.Hooks.Events.PreToolUse.Input{}, event)
      true
  """
  def parse_hook_input(json) when is_binary(json) do
    with {:ok, data} <- Jason.decode(json) do
      case data["hook_event_name"] do
        "PreToolUse" -> {:ok, PreToolUse.Input.new(data)}
        "PostToolUse" -> {:ok, PostToolUse.Input.new(data)}
        "Notification" -> {:ok, Notification.Input.new(data)}
        "UserPromptSubmit" -> {:ok, UserPromptSubmit.Input.new(data)}
        "Stop" -> {:ok, Stop.Input.new(data)}
        "SubagentStop" -> {:ok, SubagentStop.Input.new(data)}
        "PreCompact" -> {:ok, PreCompact.Input.new(data)}
        other -> {:error, "Unknown hook event name: #{inspect(other)}"}
      end
    end
  end

  def parse_hook_input(_), do: {:error, "Input must be a JSON string"}

  defmodule SimpleOutput do
    @moduledoc """
    Represents simple hook output using exit codes and stdout/stderr.

    Exit codes:
    - 0: Success, stdout shown to user (except UserPromptSubmit where it's added as context)
    - 2: Blocking error, stderr shown to Claude
    - Other: Non-blocking error, stderr shown to user
    """
    defstruct exit_code: 0,
              stdout: nil,
              stderr: nil

    @type t :: %__MODULE__{
            exit_code: non_neg_integer(),
            stdout: String.t() | nil,
            stderr: String.t() | nil
          }

    @doc """
    Creates a success output with optional stdout.
    """
    def success(stdout \\ nil) do
      %__MODULE__{exit_code: 0, stdout: stdout}
    end

    @doc """
    Creates a blocking error output with stderr message.
    """
    def block(stderr) do
      %__MODULE__{exit_code: 2, stderr: stderr}
    end

    @doc """
    Creates a non-blocking error output with stderr message.
    """
    def error(stderr, exit_code \\ 1) when exit_code != 0 and exit_code != 2 do
      %__MODULE__{exit_code: exit_code, stderr: stderr}
    end

    @doc """
    Writes the output to appropriate streams and exits with the code.
    """
    def write_and_exit(%__MODULE__{} = output) do
      if output.stdout, do: IO.puts(output.stdout)
      if output.stderr, do: IO.puts(:stderr, output.stderr)
      System.halt(output.exit_code)
    end
  end

  defimpl Jason.Encoder, for: SimpleOutput do
    alias Claude.Core.JsonUtils

    def encode(%SimpleOutput{} = output, opts) do
      output
      |> Map.from_struct()
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
      |> JsonUtils.to_camel_case()
      |> Jason.Encode.map(opts)
    end
  end
end
