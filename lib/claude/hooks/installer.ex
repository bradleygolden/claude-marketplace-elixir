defmodule Claude.Hooks.Installer do
  @moduledoc """
  Handles the installation and management of Claude hooks in the settings.json file.

  This module provides the core logic for installing, updating, and removing
  Claude hooks from a project's settings, making it easy to test and reuse
  across different interfaces (CLI, Igniter tasks, etc.).
  """

  alias Claude.Hooks

  @doc """
  Installs all Claude hooks into the given settings map.

  This function:
  1. Ensures the "hooks" key exists in settings
  2. Removes any existing Claude hooks (to avoid duplicates)
  3. Installs all registered hooks with their proper configuration

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
  def install_hooks(settings) when is_map(settings) do
    settings = Map.put_new(settings, "hooks", %{})
    claude_commands = Enum.map(Hooks.all_hooks(), fn hook -> hook.config().command end)
    settings = remove_claude_hooks(settings, claude_commands)

    hooks_by_event_and_matcher =
      Hooks.all_hooks()
      |> Enum.group_by(fn hook_module ->
        event_type =
          hook_module
          |> Module.split()
          |> Enum.at(2)

        matcher = hook_module.config().matcher

        {event_type, matcher}
      end)

    updated_hooks = get_in(settings, ["hooks"]) || %{}

    new_hooks =
      Enum.reduce(hooks_by_event_and_matcher, updated_hooks, fn {{event_type, matcher},
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

    Map.put(settings, "hooks", new_hooks)
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
    claude_commands = Enum.map(Hooks.all_hooks(), fn hook -> hook.config().command end)
    remove_claude_hooks(settings, claude_commands)
  end

  @doc """
  Formats a list of enabled hooks for display.

  ## Examples

      iex> Claude.Hooks.Installer.format_hooks_list()
      "  • Checks if Elixir files need formatting after Claude edits them\\n..."
  """
  @spec format_hooks_list() :: String.t()
  def format_hooks_list do
    Hooks.all_hooks()
    |> Enum.map(fn hook_module ->
      "  • #{hook_module.description()}"
    end)
    |> Enum.join("\n")
  end

  # Private functions

  defp remove_claude_hooks(settings, claude_commands) do
    hooks = Map.get(settings, "hooks", %{})

    updated_hooks =
      hooks
      |> Enum.map(fn
        {event_type, matchers} when is_list(matchers) ->
          updated_matchers =
            matchers
            |> Enum.map(fn matcher_obj ->
              hooks_list = Map.get(matcher_obj, "hooks", [])

              filtered_hooks =
                hooks_list
                |> Enum.reject(fn hook ->
                  Map.get(hook, "command") in claude_commands
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

    if updated_hooks == %{} do
      Map.delete(settings, "hooks")
    else
      Map.put(settings, "hooks", updated_hooks)
    end
  end
end
