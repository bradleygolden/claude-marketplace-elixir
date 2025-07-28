defmodule Claude.Hooks.Installer do
  @moduledoc """
  Handles the installation and management of Claude hooks in the settings.json file.

  This module provides the core logic for installing, updating, and removing
  Claude hooks from a project's settings, making it easy to test and reuse
  across different interfaces (CLI, Igniter tasks, etc.).
  """

  alias Claude.Hooks.Registry
  alias Claude.Settings, as: SettingsStruct

  @doc """
  Installs all Claude hooks into the given settings map.

  This function:
  1. Ensures the "hooks" key exists in settings
  2. Removes any existing Claude hooks (to avoid duplicates)
  3. Installs all registered hooks with their proper configuration
  4. Supports both built-in and custom hooks from .claude.exs

  ## Examples

      iex> Claude.Hooks.Installer.install_hooks(%{})
      %{
        "hooks" => %{
          "PostToolUse" => [...],
          "PreToolUse" => [...]
        }
      }
      
      iex> Claude.Hooks.Installer.install_hooks(%{"hooks" => %{"CustomHook" => [...]}})
      %{
        "hooks" => %{
          "CustomHook" => [...],
          "PostToolUse" => [...],
          "PreToolUse" => [...]
        }
      }
  """
  @spec install_hooks(map()) :: map()
  def install_hooks(settings_map) when is_map(settings_map) do
    settings_struct = SettingsStruct.new(settings_map)

    existing_hooks = settings_struct.hooks || %{}

    all_hooks = Registry.all_hooks()
    claude_commands = Enum.map(all_hooks, fn hook -> hook.config().command end)

    cleaned_hooks = remove_claude_hooks_from_hooks_config(existing_hooks, claude_commands)

    hooks_by_event_and_matcher =
      all_hooks
      |> Enum.group_by(fn hook_module ->
        metadata = Registry.get_hook_metadata(hook_module)
        event_type = to_event_type_string(metadata.event)
        matcher = metadata.matcher || ".*"

        {event_type, matcher}
      end)

    new_hooks =
      Enum.reduce(hooks_by_event_and_matcher, cleaned_hooks, fn {{event_type, matcher},
                                                                 hook_modules},
                                                                acc ->
        existing_matchers = Map.get(acc, event_type, [])

        matcher_index =
          Enum.find_index(existing_matchers, fn m ->
            Map.get(m, "matcher") == matcher
          end)

        hook_configs =
          Enum.map(hook_modules, fn hook_module ->
            config = hook_module.config()

            %{
              "type" => config.type,
              "command" => config.command
            }
          end)

        if matcher_index do
          updated_matchers =
            List.update_at(existing_matchers, matcher_index, fn matcher_obj ->
              existing_hooks = Map.get(matcher_obj, "hooks", [])
              Map.put(matcher_obj, "hooks", existing_hooks ++ hook_configs)
            end)

          Map.put(acc, event_type, updated_matchers)
        else
          new_matcher_obj = %{
            "matcher" => matcher,
            "hooks" => hook_configs
          }

          Map.put(acc, event_type, existing_matchers ++ [new_matcher_obj])
        end
      end)

    Map.put(settings_map, "hooks", new_hooks)
  end

  defp to_event_type_string(event_atom) do
    case event_atom do
      :pre_tool_use -> "PreToolUse"
      :post_tool_use -> "PostToolUse"
      :user_prompt_submit -> "UserPromptSubmit"
      :notification -> "Notification"
      :stop -> "Stop"
      :subagent_stop -> "SubagentStop"
      :pre_compact -> "PreCompact"
      _ -> Atom.to_string(event_atom)
    end
  end

  @doc """
  Removes all Claude hooks from the given settings map.

  This function removes hooks by matching their command strings against
  the list of known Claude hook commands.

  ## Examples

      iex> settings = %{"hooks" => %{"PostToolUse" => [...]}}
      iex> Claude.Hooks.Installer.remove_all_hooks(settings)
      %{}
  """
  @spec remove_all_hooks(map()) :: map()
  def remove_all_hooks(settings) when is_map(settings) do
    claude_commands = Enum.map(Registry.all_hooks(), fn hook -> hook.config().command end)
    remove_claude_hooks(settings, claude_commands)
  end

  @doc """
  Formats a list of enabled hooks for display.
  Distinguishes between built-in and custom hooks.

  ## Examples

      iex> Claude.Hooks.Installer.format_hooks_list()
      "  • Checks if Elixir files need formatting after Claude edits them\\n..."
  """
  @spec format_hooks_list() :: String.t()
  def format_hooks_list do
    all_hooks = Registry.all_hooks()
    built_in_hooks = Registry.built_in_hooks()
    
    {built_in, custom} = 
      Enum.split_with(all_hooks, fn hook -> hook in built_in_hooks end)
    
    built_in_list = 
      built_in
      |> Enum.map(fn hook_module ->
        "  • #{hook_module.description()}"
      end)
      |> Enum.join("\n")
    
    custom_list = 
      custom
      |> Enum.map(fn hook_module ->
        "  • [Custom] #{hook_module.description()}"
      end)
      |> Enum.join("\n")
    
    case {built_in_list, custom_list} do
      {"", ""} -> "  No hooks installed"
      {built_in, ""} -> built_in
      {"", custom} -> custom
      {built_in, custom} -> built_in <> "\n" <> custom
    end
  end

  defp remove_claude_hooks_from_hooks_config(hooks_config, claude_commands) do
    hooks_config
    |> Enum.map(fn
      {event_type, matchers} when is_list(matchers) ->
        updated_matchers =
          matchers
          |> Enum.map(fn matcher_obj ->
            hooks_list = Map.get(matcher_obj, "hooks", [])

            filtered_hooks =
              hooks_list
              |> Enum.reject(fn hook ->
                command =
                  case hook do
                    %Claude.Hooks.Hook{command: cmd} -> cmd
                    %{"command" => cmd} -> cmd
                    _ -> ""
                  end

                Enum.any?(claude_commands, fn claude_cmd ->
                  command == claude_cmd or
                    String.contains?(command, "mix claude hooks run")
                end)
              end)

            if filtered_hooks == [] do
              :remove
            else
              Map.put(matcher_obj, "hooks", filtered_hooks)
            end
          end)
          |> Enum.reject(&(&1 == :remove))

        if updated_matchers == [] do
          {event_type, :remove}
        else
          {event_type, updated_matchers}
        end

      {event_type, other} ->
        {event_type, other}
    end)
    |> Enum.reject(fn {_, value} -> value == :remove end)
    |> Map.new()
  end

  defp remove_claude_hooks(settings, claude_commands) do
    hooks = Map.get(settings, "hooks", %{})
    updated_hooks = remove_claude_hooks_from_hooks_config(hooks, claude_commands)

    if updated_hooks == %{} do
      Map.delete(settings, "hooks")
    else
      Map.put(settings, "hooks", updated_hooks)
    end
  end
end
