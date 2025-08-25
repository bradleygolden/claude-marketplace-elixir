defmodule Claude.Config do
  @moduledoc "Configuration management for Claude with plugin support."

  @doc "Read and process the Claude configuration."
  def read do
    case read_base_config() do
      {:ok, base_config} ->
        apply_plugins(base_config)

      error ->
        error
    end
  end

  @doc """
  Read the base .claude.exs file without applying plugins.

  This is useful for testing or when you need the raw configuration.
  """
  def read_base_config do
    claude_exs_path = ".claude.exs"

    if File.exists?(claude_exs_path) do
      try do
        {config, _bindings} = Code.eval_file(claude_exs_path)

        if is_map(config) do
          {:ok, config}
        else
          {:error, ".claude.exs must return a map, got: #{inspect(config)}"}
        end
      rescue
        e ->
          {:error, Exception.format(:error, e, __STACKTRACE__)}
      end
    else
      {:error, ".claude.exs not found"}
    end
  end

  defp apply_plugins(base_config) do
    case Map.get(base_config, :plugins, []) do
      [] ->
        {:ok, Map.delete(base_config, :plugins)}

      plugins when is_list(plugins) ->
        case Claude.Plugin.load_plugins(plugins) do
          {:ok, plugin_configs} ->
            final_config =
              (plugin_configs ++ [base_config])
              |> Claude.Plugin.merge_configs()
              |> Map.delete(:plugins)

            {:ok, final_config}

          {:error, errors} ->
            error_message =
              "Failed to load plugins:\n" <> Enum.join(errors, "\n")

            {:error, error_message}
        end

      plugins ->
        {:error, "plugins must be a list, got: #{inspect(plugins)}"}
    end
  end
end
