defmodule Claude.Hooks.Events.PostToolUse do
  @moduledoc """
  PostToolUse hook event structures.

  Runs immediately after a tool completes successfully.
  """

  alias Claude.Hooks.ToolInputs
  alias Claude.Core.JsonUtils

  defmodule Input do
    @moduledoc """
    Input data for PostToolUse hook events.
    """
    @derive Jason.Encoder
    defstruct [
      :session_id,
      :transcript_path,
      :cwd,
      :hook_event_name,
      :tool_name,
      :tool_input,
      :tool_response
    ]

    @type t :: %__MODULE__{
            session_id: String.t(),
            transcript_path: String.t(),
            cwd: String.t(),
            hook_event_name: String.t(),
            tool_name: String.t(),
            tool_input: map() | struct(),
            tool_response: map()
          }

    @doc """
    Creates a new PostToolUse Input struct from a map.

    The tool_input field will be parsed into the appropriate tool-specific struct
    based on the tool_name.
    """
    def new(attrs) when is_map(attrs) do
      tool_name = attrs["tool_name"]
      raw_tool_input = attrs["tool_input"] || %{}

      parsed_tool_input =
        case ToolInputs.parse_tool_input(tool_name, raw_tool_input) do
          {:ok, input} -> input
          _ -> raw_tool_input
        end

      %__MODULE__{
        session_id: attrs["session_id"],
        transcript_path: attrs["transcript_path"],
        cwd: attrs["cwd"],
        hook_event_name: attrs["hook_event_name"] || "PostToolUse",
        tool_name: tool_name,
        tool_input: parsed_tool_input,
        tool_response: attrs["tool_response"] || %{}
      }
    end

    @doc """
    Parses JSON string into PostToolUse Input struct.
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
    Output structure for PostToolUse hooks.

    Can block tool execution and provide feedback to Claude.
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
    Creates a PostToolUse Output that indicates success.
    """
    def success do
      %__MODULE__{}
    end

    @doc """
    Creates a PostToolUse Output that blocks with a reason.
    """
    def block(reason) do
      %__MODULE__{
        decision: :block,
        reason: reason
      }
    end

    @doc """
    Creates a PostToolUse Output that allows continuation.
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
