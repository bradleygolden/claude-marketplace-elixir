defmodule Claude.NestedMemories do
  @moduledoc false

  def generate(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_and_eval_claude_exs(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          nested_memories = Map.get(config, :nested_memories, %{})

          if is_map(nested_memories) and nested_memories != %{} do
            process_nested_memories(igniter, nested_memories)
          else
            igniter
          end

        _ ->
          igniter
      end
    else
      igniter
    end
  end

  defp process_nested_memories(igniter, memory_config) do
    Enum.reduce(memory_config, igniter, fn {path, rule_specs}, acc ->
      memory_file_path = Path.join(path, "CLAUDE.md")

      if File.dir?(path) do
        sync_rules_to_file(acc, memory_file_path, rule_specs)
      else
        acc
      end
    end)
  end

  defp sync_rules_to_file(igniter, file_path, rule_specs) do
    rules = Enum.map(rule_specs, &to_string/1)

    igniter
    |> Igniter.add_task("usage_rules.sync", [file_path | rules] ++ ["--yes"])
  end

  defp read_and_eval_claude_exs(igniter, path) do
    try do
      source =
        case Rewrite.source(igniter.rewrite, path) do
          {:ok, source} ->
            source

          {:error, _} ->
            igniter = Igniter.include_existing_file(igniter, path)

            case Rewrite.source(igniter.rewrite, path) do
              {:ok, source} -> source
              _ -> nil
            end
        end

      if source do
        content = Rewrite.Source.get(source, :content)

        case Code.eval_string(content) do
          {config, _bindings} when is_map(config) ->
            {:ok, config}

          _ ->
            {:error, :invalid_config}
        end
      else
        {:error, :file_not_found}
      end
    rescue
      _ -> {:error, :eval_error}
    end
  end
end
