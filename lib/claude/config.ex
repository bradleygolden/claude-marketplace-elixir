defmodule Claude.Config do
  @moduledoc """
  Handles loading and parsing of `.claude.exs` configuration files.

  This module provides functionality similar to Credo's configuration system,
  allowing users to define custom hooks and configuration in their projects.
  """

  @default_config %{
    hooks: [],
    enabled: true
  }

  @doc """
  Loads configuration from `.claude.exs` file in the project root.

  Returns a configuration map with the following structure:

      %{
        hooks: [
          %{
            module: MyApp.Hooks.CustomFormatter,
            enabled: true,
            event_type: "PostToolUse",
            config: %{...}
          }
        ],
        enabled: true
      }
  """
  def load do
    case find_config_file() do
      {:ok, path} ->
        load_from_file(path)

      :error ->
        {:ok, @default_config}
    end
  end

  @doc """
  Loads configuration from a specific file path.
  """
  def load_from_file(path) do
    try do
      {config, _binding} = Code.eval_file(path)
      validate_config(config)
    rescue
      e ->
        {:error, "Failed to load .claude.exs: #{Exception.message(e)}"}
    end
  end

  @doc """
  Finds the `.claude.exs` configuration file in the project.

  Searches in the following order:
  1. Project root directory
  2. Parent directories (up to `max_depth` levels, default 3)
  
  ## Options
  
  * `:max_depth` - Maximum number of parent directories to search (default: 3)
  """
  def find_config_file(opts \\ []) do
    max_depth = Keyword.get(opts, :max_depth, 3)
    project_root = Claude.Core.Project.root()

    paths = build_search_paths(project_root, max_depth)

    case Enum.find(paths, &File.exists?/1) do
      nil -> :error
      path -> {:ok, path}
    end
  end
  
  defp build_search_paths(root, max_depth) do
    0..max_depth
    |> Enum.map(fn depth ->
      path_parts = [root] ++ List.duplicate("..", depth) ++ [".claude.exs"]
      Path.join(path_parts)
    end)
  end

  defp validate_config(config) when is_map(config) do
    config = Map.merge(@default_config, config)

    with :ok <- validate_hooks(config[:hooks]),
         :ok <- validate_enabled(config[:enabled]) do
      {:ok, config}
    end
  end

  defp validate_config(_) do
    {:error, "Configuration must be a map"}
  end

  defp validate_hooks(hooks) when is_list(hooks) do
    if Enum.all?(hooks, &valid_hook?/1) do
      :ok
    else
      {:error, "Invalid hook configuration"}
    end
  end

  defp validate_hooks(_), do: {:error, "hooks must be a list"}

  defp validate_enabled(enabled) when is_boolean(enabled), do: :ok
  defp validate_enabled(_), do: {:error, "enabled must be a boolean"}

  defp valid_hook?(%{module: module} = hook) when is_atom(module) do
    Map.get(hook, :enabled, true) |> is_boolean() &&
      Map.get(hook, :config, %{}) |> is_map() &&
      valid_event_type?(Map.get(hook, :event_type))
  end

  defp valid_hook?(_), do: false

  defp valid_event_type?(nil), do: true

  defp valid_event_type?(type) when is_binary(type) do
    type in ["PostToolUse", "PreToolUse", "UserPromptSubmit"]
  end

  defp valid_event_type?(_), do: false
end
