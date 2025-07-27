defmodule Claude.Hooks.Events.Stop do
  @moduledoc """
  Stop hook event structures.

  Runs when the main Claude Code agent has finished responding.
  """

  alias Claude.Core.JsonUtils

  defmodule Input do
    @moduledoc """
    Input data for Stop hook events.

    Note: Stop events do not include a cwd field.
    """
    @derive Jason.Encoder
    defstruct [:session_id, :transcript_path, :hook_event_name, :stop_hook_active]

    @type t :: %__MODULE__{
            session_id: String.t(),
            transcript_path: String.t(),
            hook_event_name: String.t(),
            stop_hook_active: boolean()
          }

    @doc """
    Creates a new Stop Input struct from a map.
    """
    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        session_id: attrs["session_id"],
        transcript_path: attrs["transcript_path"],
        hook_event_name: attrs["hook_event_name"] || "Stop",
        stop_hook_active: attrs["stop_hook_active"] || false
      }
    end

    @doc """
    Parses JSON string into Stop Input struct.
    """
    def from_json(json) when is_binary(json) do
      case Jason.decode(json) do
        {:ok, data} -> {:ok, new(data)}
        {:error, _} = error -> error
      end
    end
  end

  defmodule Output do
    @moduledoc """
    Output structure for Stop hooks.

    Can prevent Claude from stopping and provide instructions to continue.
    """
    defstruct continue: true,
              stop_reason: nil,
              suppress_output: false,
              decision: nil,
              reason: nil

    @type decision :: :block | nil

    @type t :: %__MODULE__{
            continue: boolean(),
            stop_reason: String.t() | nil,
            suppress_output: boolean(),
            decision: decision(),
            reason: String.t() | nil
          }

    @doc """
    Creates a Stop Output that blocks Claude from stopping.
    """
    def block(reason) do
      %__MODULE__{
        decision: :block,
        reason: reason
      }
    end

    @doc """
    Creates a Stop Output that allows Claude to stop.
    """
    def allow do
      %__MODULE__{}
    end

  end

  defimpl Jason.Encoder, for: Output do
    def encode(%Output{} = output, opts) do
      output
      |> Map.from_struct()
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
      |> JsonUtils.to_camel_case()
      |> then(fn map ->
        if map["decision"] do
          Map.put(map, "decision", to_string(map["decision"]))
        else
          map
        end
      end)
      |> Jason.Encode.map(opts)
    end
  end
end
