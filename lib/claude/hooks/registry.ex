defmodule Claude.Hooks.Registry do
  @moduledoc """
  Hook registry that provides centralized hook discovery and management.

  This module provides:
  - Centralized list of available hooks (built-in and custom)
  - Hook metadata introspection
  - Efficient hook lookup by identifier
  - Dynamic discovery of custom hooks from .claude.exs

  Custom hooks can be registered by adding them to the `hooks` array in .claude.exs:

      # .claude.exs
      %{
        hooks: [
          MyProject.Hooks.CustomHook
        ]
      }

  Custom hooks must implement the Claude.Hooks.Hook.Behaviour.
  """

  @known_hooks [
    Claude.Hooks.PostToolUse.ElixirFormatter,
    Claude.Hooks.PostToolUse.CompilationChecker,
    Claude.Hooks.PreToolUse.PreCommitCheck
  ]

  @doc """
  Returns all available hook modules.
  Includes both built-in hooks and custom hooks from .claude.exs.
  """
  def all_hooks do
    built_in = @known_hooks
    custom = discover_custom_hooks()
    built_in ++ custom
  end

  @doc """
  Finds a hook by its identifier.
  """
  def find_by_identifier(identifier) do
    all_hooks()
    |> Enum.find(fn hook_module ->
      hook_identifier(hook_module) == identifier
    end)
  end

  @doc """
  Returns the identifier for a hook module.
  """
  def hook_identifier(hook_module) do
    if function_exported?(hook_module, :__hook_identifier__, 0) do
      hook_module.__hook_identifier__()
    else
      if custom_hook?(hook_module) do
        hook_module
        |> Module.split()
        |> Enum.map(&Macro.underscore/1)
        |> Enum.join(".")
      else
        Claude.Hooks.generate_identifier(hook_module)
      end
    end
  end

  @doc """
  Returns all hooks grouped by event type.
  """
  def hooks_by_event do
    all_hooks()
    |> Enum.group_by(&get_hook_event/1)
  end

  @doc """
  Returns all hooks for a specific event type.
  """
  def hooks_for_event(event) when is_atom(event) do
    all_hooks()
    |> Enum.filter(fn hook_module ->
      get_hook_event(hook_module) == event
    end)
  end

  @doc """
  Returns metadata for all hooks.
  """
  def all_hook_metadata do
    all_hooks()
    |> Enum.map(&get_hook_metadata/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Gets metadata for a specific hook module.
  """
  def get_hook_metadata(hook_module) do
    if function_exported?(hook_module, :__hook_metadata__, 0) do
      hook_module.__hook_metadata__()
    else
      %{
        module: hook_module,
        event: get_hook_event(hook_module),
        matcher: get_hook_matcher(hook_module),
        identifier: hook_identifier(hook_module),
        description: get_hook_description(hook_module)
      }
    end
  end

  defp get_hook_event(hook_module) do
    cond do
      function_exported?(hook_module, :__hook_event__, 0) ->
        hook_module.__hook_event__()

      match?({:module, _}, Code.ensure_compiled(hook_module)) ->
        hook_module
        |> Module.split()
        |> Enum.find_value(fn
          "PreToolUse" -> :pre_tool_use
          "PostToolUse" -> :post_tool_use
          "UserPromptSubmit" -> :user_prompt_submit
          "Notification" -> :notification
          "Stop" -> :stop
          "SubagentStop" -> :subagent_stop
          "PreCompact" -> :pre_compact
          _ -> nil
        end)

      true ->
        nil
    end
  end

  defp get_hook_matcher(hook_module) do
    if function_exported?(hook_module, :__hook_matcher__, 0) do
      hook_module.__hook_matcher__()
    else
      "*"
    end
  end

  defp get_hook_description(hook_module) do
    if function_exported?(hook_module, :description, 0) do
      hook_module.description()
    else
      ""
    end
  end

  @doc """
  Returns only the built-in hooks.
  """
  def built_in_hooks do
    @known_hooks
  end

  @doc """
  Returns only the custom hooks discovered from .claude.exs.
  """
  def custom_hooks do
    discover_custom_hooks()
  end

  defp discover_custom_hooks do
    case load_claude_exs_hooks() do
      {:ok, hooks} -> validate_hooks(hooks)
      _ -> []
    end
  end

  defp load_claude_exs_hooks do
    exs_path = Path.join(Claude.Core.Project.root(), ".claude.exs")

    case File.read(exs_path) do
      {:ok, content} ->
        try do
          {result, _binding} = Code.eval_string(content, [], file: exs_path)

          case result do
            %{hooks: hooks} when is_list(hooks) ->
              {:ok, hooks}

            _ ->
              {:ok, []}
          end
        rescue
          _error ->
            {:ok, []}
        end

      _ ->
        {:ok, []}
    end
  end

  defp validate_hooks(hook_modules) do
    hook_modules
    |> Enum.filter(&is_atom/1)
    |> Enum.filter(&validate_hook_module/1)
    |> Enum.reject(&(&1 in @known_hooks))
    |> Enum.uniq()
  end

  defp validate_hook_module(module) do
    with {:module, _} <- Code.ensure_compiled(module),
         true <- function_exported?(module, :config, 0),
         true <- function_exported?(module, :run, 1),
         true <- function_exported?(module, :description, 0),
         %Claude.Hooks.Hook{} <- module.config() do
      true
    else
      _ -> false
    end
  end

  @doc """
  Checks if a module is a custom hook (not built-in).
  """
  def custom_hook?(hook_module) do
    hook_module not in @known_hooks
  end
end
