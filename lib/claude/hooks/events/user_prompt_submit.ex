defmodule Claude.Hooks.Events.UserPromptSubmit do
  @moduledoc """
  UserPromptSubmit hook event structures.

  Runs when the user submits a prompt, before Claude processes it.
  """

  alias Claude.Core.JsonUtils

  defmodule Input do
    @moduledoc """
    Input data for UserPromptSubmit hook events.
    """
    @derive Jason.Encoder
    defstruct [:session_id, :transcript_path, :cwd, :hook_event_name, :prompt]

    @type t :: %__MODULE__{
            session_id: String.t(),
            transcript_path: String.t(),
            cwd: String.t(),
            hook_event_name: String.t(),
            prompt: String.t()
          }

    @doc """
    Creates a new UserPromptSubmit Input struct from a map.
    """
    def new(attrs) when is_map(attrs) do
      %__MODULE__{
        session_id: attrs["session_id"],
        transcript_path: attrs["transcript_path"],
        cwd: attrs["cwd"],
        hook_event_name: attrs["hook_event_name"] || "UserPromptSubmit",
        prompt: attrs["prompt"]
      }
    end

    @doc """
    Parses JSON string into UserPromptSubmit Input struct.
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
    Output structure for UserPromptSubmit hooks.

    Can block prompts and add additional context.
    """
    defstruct continue: true,
              stop_reason: nil,
              suppress_output: false,
              decision: nil,
              reason: nil,
              hook_specific_output: nil

    @type decision :: :block | nil

    @type hook_specific :: %{
            hook_event_name: String.t(),
            additional_context: String.t() | nil
          }

    @type t :: %__MODULE__{
            continue: boolean(),
            stop_reason: String.t() | nil,
            suppress_output: boolean(),
            decision: decision(),
            reason: String.t() | nil,
            hook_specific_output: hook_specific() | nil
          }

    @doc """
    Creates a UserPromptSubmit Output that allows the prompt.
    """
    def allow do
      %__MODULE__{}
    end

    @doc """
    Creates a UserPromptSubmit Output that allows with additional context.
    """
    def allow_with_context(context) do
      %__MODULE__{
        hook_specific_output: %{
          hook_event_name: "UserPromptSubmit",
          additional_context: context
        }
      }
    end

    @doc """
    Creates a UserPromptSubmit Output that blocks the prompt.
    """
    def block(reason) do
      %__MODULE__{
        decision: :block,
        reason: reason
      }
    end

    @doc """
    Creates a UserPromptSubmit Output that adds context.
    """
    def add_context(context) do
      %__MODULE__{
        hook_specific_output: %{
          hook_event_name: "UserPromptSubmit",
          additional_context: context
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
