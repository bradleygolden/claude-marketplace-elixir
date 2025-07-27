defmodule Claude.Hooks.Events.Notification do
  @moduledoc """
  Notification hook event structures.

  Runs when Claude Code sends notifications, such as permission requests
  or idle prompts.
  """

  defmodule Input do
    @moduledoc """
    Input data for Notification hook events.
    """
    @derive Jason.Encoder
    defstruct [:session_id, :transcript_path, :cwd, :hook_event_name, :message]

    @type t :: %__MODULE__{
            session_id: String.t(),
            transcript_path: String.t(),
            cwd: String.t(),
            hook_event_name: String.t(),
            message: String.t()
          }

    @doc """
    Creates a new Notification Input struct from a map.
    """
    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        session_id: attrs["session_id"],
        transcript_path: attrs["transcript_path"],
        cwd: attrs["cwd"],
        hook_event_name: attrs["hook_event_name"] || "Notification",
        message: attrs["message"]
      }
    end

    @doc """
    Parses JSON string into Notification Input struct.
    """
    def from_json(json) when is_binary(json) do
      case Jason.decode(json) do
        {:ok, data} -> {:ok, new(data)}
        {:error, _} = error -> error
      end
    end
  end

  # Notification hooks typically use SimpleOutput or basic exit codes
  # No specific output structure needed
  defmodule Output do
    defdelegate success(stdout \\ nil), to: Claude.Hooks.Events.Common.SimpleOutput
    defdelegate error(stderr, exit_code \\ 1), to: Claude.Hooks.Events.Common.SimpleOutput
    defdelegate block(stderr), to: Claude.Hooks.Events.Common.SimpleOutput
  end
end
