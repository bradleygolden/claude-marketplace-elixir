defmodule Claude.Hooks.Registry do
  @moduledoc """
  Registry for managing both built-in and user-defined hooks.

  This module provides dynamic hook discovery and registration,
  allowing users to extend Claude with custom hooks defined in
  their `.claude.exs` configuration file.
  """

  alias Claude.Config
  alias Claude.Hooks.Hook

  @builtin_hooks [
    Claude.Hooks.PostToolUse.ElixirFormatter,
    Claude.Hooks.PostToolUse.CompilationChecker,
    Claude.Hooks.PreToolUse.PreCommitCheck
  ]

  @doc """
  Returns all available hooks, including built-in and user-defined hooks.

  User-defined hooks are loaded from `.claude.exs` configuration file.
  """
  def all_hooks do
    builtin = builtin_hooks()
    custom = custom_hooks()

    builtin ++ custom
  end

  @doc """
  Returns only the built-in hooks.
  """
  def builtin_hooks do
    @builtin_hooks
  end

  @doc """
  Returns user-defined hooks from configuration.
  """
  def custom_hooks do
    case Config.load() do
      {:ok, config} ->
        config
        |> Map.get(:hooks, [])
        |> Enum.filter(&(&1[:enabled] != false))
        |> Enum.map(& &1[:module])
        |> Enum.filter(&hook_module?/1)

      {:error, _} ->
        []
    end
  end

  @doc """
  Finds a hook module by its identifier.
  """
  def find_by_identifier(identifier) do
    all_hooks()
    |> Enum.find(fn hook ->
      Hook.identifier(hook) == identifier
    end)
  end

  @doc """
  Groups hooks by event type and matcher.
  """
  def group_by_event_and_matcher(hooks) do
    hooks
    |> Enum.group_by(fn hook ->
      config = hook.config()
      {event_type_for(hook), config.matcher}
    end)
  end

  @doc """
  Validates that a module implements the hook behaviour.
  """
  def hook_module?(module) when is_atom(module) do
    Code.ensure_loaded?(module) &&
      function_exported?(module, :config, 0) &&
      function_exported?(module, :run, 2) &&
      function_exported?(module, :description, 0)
  end

  def hook_module?(_), do: false

  @doc """
  Returns configuration for a specific hook module.

  This includes any user-specific configuration from `.claude.exs`.
  """
  def hook_config(module) do
    case Config.load() do
      {:ok, config} ->
        config
        |> Map.get(:hooks, [])
        |> Enum.find(fn hook -> hook[:module] == module end)
        |> case do
          nil -> %{}
          hook -> Map.get(hook, :config, %{})
        end

      {:error, _} ->
        %{}
    end
  end

  @doc """
  Returns the event type for a hook module.

  First checks if the hook has a configured event type in .claude.exs,
  then falls back to inferring from the module name.
  """
  def event_type_for(module) do
    case Config.load() do
      {:ok, config} ->
        config
        |> Map.get(:hooks, [])
        |> Enum.find(fn hook -> hook[:module] == module end)
        |> case do
          nil -> Hook.event_type(module)
          hook -> Map.get(hook, :event_type, Hook.event_type(module))
        end

      {:error, _} ->
        Hook.event_type(module)
    end
  end

  @doc """
  Returns full hook information for a module, including custom configuration.
  """
  def hook_info(module) do
    case Config.load() do
      {:ok, config} ->
        config
        |> Map.get(:hooks, [])
        |> Enum.find(fn hook -> hook[:module] == module end)
        |> case do
          nil ->
            %{module: module, enabled: true, event_type: Hook.event_type(module), config: %{}}

          hook ->
            %{
              module: module,
              enabled: Map.get(hook, :enabled, true),
              event_type: Map.get(hook, :event_type, Hook.event_type(module)),
              config: Map.get(hook, :config, %{})
            }
        end

      {:error, _} ->
        %{module: module, enabled: true, event_type: Hook.event_type(module), config: %{}}
    end
  end
end
