defmodule Claude.Settings do
  @moduledoc """
  Struct representation of Claude Code settings.
  
  Provides type-safe access to Claude Code configuration options
  that can be stored in settings.json files. Currently focused on
  hooks configuration.
  """

  alias Claude.Core.JsonUtils
  alias Claude.Hooks.Hook

  defstruct [:hooks]

  # Hook event types from Claude.Hooks.Events
  @type hook_event_type ::
          :PreToolUse
          | :PostToolUse
          | :Notification
          | :UserPromptSubmit
          | :Stop
          | :SubagentStop
          | :PreCompact

  # Matcher configuration that groups hooks by pattern
  # Note: The Hook struct has a matcher field, but in settings.json, the matcher
  # is at the matcher_config level, not in individual hooks
  @type matcher_config :: %{
          required(String.t()) => String.t(),           # "matcher" => "*.ex"
          required(String.t()) => [Hook.t() | map()]   # "hooks" => [...] - can be Hook structs or plain maps
        }

  # The hooks configuration maps event types to lists of matcher configs
  @type hooks_config :: %{
          optional(String.t()) => [matcher_config()]
        }

  @type t :: %__MODULE__{
          hooks: hooks_config() | nil
        }

  @doc """
  Creates a new Settings struct from a map.
  
  Accepts both camelCase (from JSON) and snake_case keys.
  Optionally converts hook maps to Hook structs if they have the required fields.
  
  Supports both hook formats:
  - Simple: {"PreToolUse": {"Bash": "echo 'Running...'"}}
  - Complex: {"PreToolUse": [{"matcher": "Bash", "hooks": [...]}]}
  """
  def new(attrs) when is_map(attrs) do
    # Convert camelCase keys to snake_case for easier access
    normalized = normalize_keys(attrs)
    
    %__MODULE__{
      hooks: parse_hooks(normalized["hooks"])
    }
  end

  @doc """
  Parses JSON string into Settings struct.
  """
  def from_json(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, data} -> {:ok, new(data)}
      {:error, _} = error -> error
    end
  end

  # Private helpers

  defp normalize_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} ->
      key = k |> to_string() |> Macro.underscore()
      {key, v}
    end)
    |> Map.new()
  end

  defp parse_hooks(nil), do: nil
  
  defp parse_hooks(hooks) when is_map(hooks) do
    hooks
    |> Enum.map(fn {event_type, matchers} ->
      parsed_matchers = parse_matchers(matchers)
      {event_type, parsed_matchers}
    end)
    |> Map.new()
  end

  defp parse_matchers(matchers) when is_list(matchers) do
    Enum.map(matchers, &parse_matcher/1)
  end
  
  # Handle simple format: {"Bash": "echo 'Running...'"}
  defp parse_matchers(simple_map) when is_map(simple_map) do
    simple_map
    |> Enum.map(fn {tool, command} ->
      %{
        "matcher" => tool,
        "hooks" => [parse_hook(command)]
      }
    end)
  end
  
  defp parse_matchers(_), do: []

  defp parse_matcher(matcher) when is_map(matcher) do
    hooks = Map.get(matcher, "hooks", [])
    parsed_hooks = Enum.map(hooks, &parse_hook/1)
    
    %{
      "matcher" => Map.get(matcher, "matcher"),
      "hooks" => parsed_hooks
    }
  end

  defp parse_hook(%Hook{} = hook), do: hook
  
  defp parse_hook(hook_map) when is_map(hook_map) do
    # Try to convert to Hook struct if it has the required fields
    type = Map.get(hook_map, "type")
    command = Map.get(hook_map, "command")
    
    if type && command do
      # Note: Hook struct in settings.json doesn't use the matcher field
      # The matcher is at the matcher_config level
      Hook.new(%{type: type, command: command})
    else
      # Return as-is if it doesn't match Hook structure
      hook_map
    end
  end
  
  defp parse_hook(command) when is_binary(command) do
    # Handle simple string commands by converting to Hook struct
    Hook.new(%{type: "command", command: command})
  end

  defimpl Jason.Encoder do
    def encode(%Claude.Settings{hooks: nil}, opts) do
      Jason.Encode.map(%{}, opts)
    end

    def encode(%Claude.Settings{hooks: hooks}, opts) do
      # Convert hooks to proper JSON structure
      json_hooks = 
        hooks
        |> Enum.map(fn {event_type, matchers} ->
          json_matchers = 
            matchers
            |> Enum.map(fn matcher ->
              hooks_list = Map.get(matcher, "hooks", [])
              json_hooks_list = Enum.map(hooks_list, &encode_hook/1)
              
              %{
                "matcher" => Map.get(matcher, "matcher"),
                "hooks" => json_hooks_list
              }
            end)
          
          {event_type, json_matchers}
        end)
        |> Map.new()
      
      # Apply camelCase conversion and encode
      %{"hooks" => json_hooks}
      |> JsonUtils.to_camel_case()
      |> Jason.Encode.map(opts)
    end

    # Encode Hook structs with only type and command fields
    defp encode_hook(%Hook{type: type, command: command}) do
      %{"type" => type, "command" => command}
    end
    
    # Pass through plain maps as-is
    defp encode_hook(map) when is_map(map), do: map
  end
end