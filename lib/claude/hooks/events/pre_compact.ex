defmodule Claude.Hooks.Events.PreCompact do
  @moduledoc """
  PreCompact hook event structures.

  Runs before Claude Code is about to run a compact operation.
  """

  defmodule Input do
    @moduledoc """
    Input data for PreCompact hook events.

    Note: PreCompact events do not include a cwd field.
    """
    @derive Jason.Encoder
    defstruct [:session_id, :transcript_path, :hook_event_name, :trigger, :custom_instructions]

    @type trigger :: :manual | :auto

    @type t :: %__MODULE__{
            session_id: String.t(),
            transcript_path: String.t(),
            hook_event_name: String.t(),
            trigger: trigger(),
            custom_instructions: String.t()
          }

    @doc """
    Creates a new PreCompact Input struct from a map.
    """
    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        session_id: attrs["session_id"],
        transcript_path: attrs["transcript_path"],
        hook_event_name: attrs["hook_event_name"] || "PreCompact",
        trigger: parse_trigger(attrs["trigger"]),
        custom_instructions: attrs["custom_instructions"] || ""
      }
    end

    @doc """
    Parses JSON string into PreCompact Input struct.
    """
    def from_json(json) when is_binary(json) do
      case Jason.decode(json) do
        {:ok, data} -> {:ok, new(data)}
        {:error, _} = error -> error
      end
    end

    defp parse_trigger("manual"), do: :manual
    defp parse_trigger("auto"), do: :auto
    defp parse_trigger(_), do: nil
  end
end
