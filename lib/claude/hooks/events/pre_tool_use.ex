defmodule Claude.Hooks.Events.PreToolUse do
  @moduledoc """
  PreToolUse hook event structures.

  Runs after Claude creates tool parameters and before processing the tool call.
  """

  alias Claude.Hooks.ToolInputs
  alias Claude.Core.JsonUtils

  defmodule Input do
    @moduledoc """
    Input data for PreToolUse hook events.
    """
    @derive Jason.Encoder
    defstruct [:session_id, :transcript_path, :cwd, :hook_event_name, :tool_name, :tool_input]

    @type t :: %__MODULE__{
            session_id: String.t(),
            transcript_path: String.t(),
            cwd: String.t(),
            hook_event_name: String.t(),
            tool_name: String.t(),
            tool_input: map() | struct()
          }

    @doc """
    Creates a new PreToolUse Input struct from a map.

    The tool_input field will be parsed into the appropriate tool-specific struct
    based on the tool_name.
    """
    def new(attrs) when is_map(attrs) do
      tool_name = attrs["tool_name"]
      raw_tool_input = attrs["tool_input"] || %{}

      parsed_tool_input =
        if is_binary(tool_name) do
          case ToolInputs.parse_tool_input(tool_name, raw_tool_input) do
            {:ok, input} -> input
            _ -> raw_tool_input
          end
        else
          raw_tool_input
        end

      %__MODULE__{
        session_id: attrs["session_id"],
        transcript_path: attrs["transcript_path"],
        cwd: attrs["cwd"],
        hook_event_name: attrs["hook_event_name"] || "PreToolUse",
        tool_name: tool_name,
        tool_input: parsed_tool_input
      }
    end

    @doc """
    Parses JSON string into PreToolUse Input struct.
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
    Output structure for PreToolUse hooks.

    Supports permission decisions (allow/deny/ask) and backward compatibility
    with deprecated decision/reason fields.
    """
    defstruct continue: true,
              stop_reason: nil,
              suppress_output: false,
              hook_specific_output: nil,
              decision: nil,
              reason: nil

    @type permission_decision :: :allow | :deny | :ask
    @type deprecated_decision :: :approve | :block

    @type hook_specific :: %{
            hook_event_name: String.t(),
            permission_decision: permission_decision(),
            permission_decision_reason: String.t() | nil
          }

    @type t :: %__MODULE__{
            continue: boolean(),
            stop_reason: String.t() | nil,
            suppress_output: boolean(),
            hook_specific_output: hook_specific() | nil,
            decision: deprecated_decision() | nil,
            reason: String.t() | nil
          }

    @doc """
    Creates a PreToolUse Output with an allow decision.
    """
    def allow(reason \\ nil) do
      %__MODULE__{
        hook_specific_output: %{
          hook_event_name: "PreToolUse",
          permission_decision: :allow,
          permission_decision_reason: reason
        }
      }
    end

    @doc """
    Creates a PreToolUse Output with a deny decision.
    """
    def deny(reason) do
      %__MODULE__{
        hook_specific_output: %{
          hook_event_name: "PreToolUse",
          permission_decision: :deny,
          permission_decision_reason: reason
        }
      }
    end

    @doc """
    Creates a PreToolUse Output with an ask decision.
    """
    def ask(reason \\ nil) do
      %__MODULE__{
        hook_specific_output: %{
          hook_event_name: "PreToolUse",
          permission_decision: :ask,
          permission_decision_reason: reason
        }
      }
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
        if map["hookSpecificOutput"] do
          original_hook_output = map["hookSpecificOutput"]

          hook_output =
            original_hook_output
            |> Enum.reject(fn {_k, v} -> is_nil(v) end)
            |> Map.new()
            |> Map.put(
              "permissionDecision",
              to_string(original_hook_output["permissionDecision"])
            )

          Map.put(map, "hookSpecificOutput", hook_output)
        else
          map
        end
      end)
      |> Jason.Encode.map(opts)
    end
  end
end
