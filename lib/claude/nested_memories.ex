defmodule Claude.NestedMemories do
  @moduledoc false

  alias Claude.Documentation

  def generate(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_config_with_plugins(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          nested_memories = Map.get(config, :nested_memories, %{})

          if is_map(nested_memories) and nested_memories != %{} do
            igniter
            |> process_nested_memories(nested_memories)
            |> Igniter.add_task("nested_memories.generate")
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
    igniter = cleanup_orphaned_claude_files(igniter, memory_config)

    Enum.reduce(memory_config, igniter, fn {path, items}, acc ->
      memory_file_path =
        case path do
          "." -> "CLAUDE.md"
          dir -> Path.join(dir, "CLAUDE.md")
        end

      should_process =
        path == "." or File.dir?(path)

      if should_process do
        {rules, docs} = partition_memory_items(items)

        acc
        |> sync_rules_to_file(memory_file_path, rules)
        |> append_documentation_references(memory_file_path, docs)
      else
        acc
      end
    end)
  end

  defp partition_memory_items(items) do
    Enum.split_with(items, fn
      {:url, _} -> false
      {:url, _, _} -> false
      {:file, _} -> false
      {:file, _, _} -> false
      item when is_atom(item) or is_binary(item) -> true
      _ -> false
    end)
  end

  defp sync_rules_to_file(igniter, file_path, rule_specs) when rule_specs != [] do
    rules = Enum.map(rule_specs, &to_string/1)

    igniter
    |> Igniter.add_task("usage_rules.sync", [file_path | rules] ++ ["--yes"])
  end

  defp sync_rules_to_file(igniter, _file_path, []), do: igniter

  defp append_documentation_references(igniter, _file_path, []), do: igniter

  defp append_documentation_references(igniter, file_path, docs) do
    if Igniter.exists?(igniter, file_path) do
      igniter
      |> Igniter.update_file(file_path, fn source ->
        current_content = Rewrite.Source.get(source, :content)

        updated_content =
          Documentation.process_references(current_content, docs)

        Rewrite.Source.update(source, :content, updated_content)
      end)
    else
      empty_content = ""

      updated_content =
        Documentation.process_references(empty_content, docs)

      igniter
      |> Igniter.create_new_file(file_path, updated_content)
    end
  end

  defp cleanup_orphaned_claude_files(igniter, memory_config) do
    configured_paths = Map.keys(memory_config) |> MapSet.new()
    claude_files = find_existing_claude_files_from_igniter(igniter)

    Enum.reduce(claude_files, igniter, fn claude_file_path, acc ->
      dir_path = extract_directory_from_claude_file(claude_file_path)

      if not MapSet.member?(configured_paths, dir_path) do
        remove_claude_file(acc, claude_file_path)
      else
        acc
      end
    end)
  end

  defp find_existing_claude_files_from_igniter(igniter) do
    igniter.rewrite
    |> Rewrite.sources()
    |> Enum.map(&Rewrite.Source.get(&1, :path))
    |> Enum.filter(&String.ends_with?(&1, "/CLAUDE.md"))
    |> Enum.reject(&(&1 == "CLAUDE.md"))
  end

  defp extract_directory_from_claude_file(claude_file_path) do
    case Path.dirname(claude_file_path) do
      "." -> "."
      dir -> dir
    end
  end

  defp remove_claude_file(igniter, claude_file_path) do
    if Igniter.exists?(igniter, claude_file_path) do
      igniter
      |> Igniter.update_file(claude_file_path, fn source ->
        current_content = Rewrite.Source.get(source, :content)

        cleaned_content =
          current_content
          |> String.replace(
            ~r/<!-- documentation-references-start -->.*<!-- documentation-references-end -->/s,
            ""
          )
          |> String.trim_trailing()

        final_content = if String.trim(cleaned_content) == "", do: "", else: cleaned_content

        Rewrite.Source.update(source, :content, final_content)
      end)
    else
      igniter
    end
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

  defp read_config_with_plugins(igniter, path) do
    case read_and_eval_claude_exs(igniter, path) do
      {:ok, base_config} when is_map(base_config) ->
        apply_plugins_to_config(base_config)

      error ->
        error
    end
  end

  defp apply_plugins_to_config(base_config) do
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

          {:error, _errors} ->
            {:ok, Map.delete(base_config, :plugins)}
        end

      _plugins ->
        {:ok, Map.delete(base_config, :plugins)}
    end
  end
end
