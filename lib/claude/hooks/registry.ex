defmodule Claude.Hooks.Registry do
  @moduledoc """
  Hook registry that provides centralized hook discovery and management.

  This module provides:
  - Centralized list of available hooks
  - Hook metadata introspection
  - Efficient hook lookup by identifier

  In the future, this can be extended to automatically discover hooks
  that use the Claude.Hook behaviour.
  """

  @known_hooks [
    Claude.Hooks.PostToolUse.ElixirFormatter,
    Claude.Hooks.PostToolUse.CompilationChecker,
    Claude.Hooks.PreToolUse.PreCommitCheck
  ]

  @doc """
  Returns all available hook modules.
  """
  def all_hooks do
    @known_hooks
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
      Claude.Hooks.generate_identifier(hook_module)
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
end
