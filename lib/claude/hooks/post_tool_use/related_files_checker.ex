defmodule Claude.Hooks.PostToolUse.RelatedFilesChecker do
  @moduledoc """
  Suggests related files that might need updates when certain files are modified.
  
  This hook helps ensure consistency across the codebase by reminding developers
  to consider updating related files when making changes.
  """

  @behaviour Claude.Hooks.Hook.Behaviour

  require Logger

  @impl true
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "cd $CLAUDE_PROJECT_DIR && mix claude hooks run post_tool_use.related_files_checker \"$1\" \"$2\"",
      matcher: "Edit|MultiEdit|Write"
    }
  end

  @impl true
  def description do
    "Suggests related files that might need updates when files are modified"
  end

  @impl true
  def run(tool_name, json_params) do
    with {:ok, params} <- Jason.decode(json_params),
         file_path when is_binary(file_path) <- get_file_path(tool_name, params),
         {:ok, related_files} <- find_related_files(file_path) do
      
      if related_files != [] do
        Logger.info("💡 Consider checking these related files:")
        
        Enum.each(related_files, fn {file, reason} ->
          if File.exists?(file) do
            Logger.info("  • #{file} - #{reason}")
          else
            Logger.info("  • #{file} - #{reason} (create if needed)")
          end
        end)
      end
      
      :ok
    else
      _ -> :ok
    end
  end

  defp get_file_path("Write", %{"file_path" => path}), do: path
  defp get_file_path("Edit", %{"file_path" => path}), do: path
  defp get_file_path("MultiEdit", %{"file_path" => path}), do: path
  defp get_file_path(_, _), do: nil

  defp find_related_files(file_path) do
    related = []
    
    # Get configuration for custom rules
    config = Claude.Hooks.Registry.hook_config(__MODULE__)
    custom_rules = Map.get(config, :rules, [])
    
    # Apply built-in rules
    related = apply_builtin_rules(file_path, related)
    
    # Apply custom rules from configuration
    related = apply_custom_rules(file_path, related, custom_rules)
    
    {:ok, Enum.uniq(related)}
  end

  defp apply_builtin_rules(file_path, related) do
    cond do
      String.starts_with?(file_path, "lib/") && String.ends_with?(file_path, ".ex") ->
        test_path = file_path
        |> String.replace_prefix("lib/", "test/")
        |> String.replace_suffix(".ex", "_test.exs")
        
        [{test_path, "corresponding test file"} | related]
      
      String.starts_with?(file_path, "test/") && String.ends_with?(file_path, "_test.exs") ->
        impl_path = file_path
        |> String.replace_prefix("test/", "lib/")
        |> String.replace_suffix("_test.exs", ".ex")
        
        [{impl_path, "implementation file"} | related]
      
      String.ends_with?(file_path, "lib/claude/hooks.ex") ->
        [{"lib/claude/hooks/registry.ex", "hook registry might need updates"} | related]
      
      String.contains?(file_path, "/hooks/") && String.ends_with?(file_path, ".ex") ->
        related
        |> maybe_add("README.md", "documentation might need updates")
        |> maybe_add("test/claude/hooks/registry_test.exs", "registry tests might need updates")
      
      String.ends_with?(file_path, "lib/claude/config.ex") ->
        related
        |> maybe_add("lib/claude/hooks/registry.ex", "uses configuration")
        |> maybe_add("test/claude/config_test.exs", "configuration tests")
      
      String.contains?(file_path, "/cli/") && String.ends_with?(file_path, ".ex") ->
        maybe_add(related, "lib/claude/cli/help.ex", "help text might need updates")
      
      # When modifying mix tasks, suggest checking CLI delegation
      String.starts_with?(file_path, "lib/mix/tasks/") ->
        maybe_add(related, "lib/claude/cli.ex", "CLI might delegate to this task")
      
      true ->
        related
    end
  end

  defp apply_custom_rules(file_path, related, custom_rules) do
    Enum.reduce(custom_rules, related, fn rule, acc ->
      case rule do
        %{pattern: pattern, suggests: suggestions} when is_binary(pattern) and is_list(suggestions) ->
          if match_pattern?(file_path, pattern) do
            new_suggestions = Enum.flat_map(suggestions, fn
              %{file: file_pattern, reason: reason} -> 
                expand_file_pattern(file_pattern, reason)
              file_pattern when is_binary(file_pattern) -> 
                expand_file_pattern(file_pattern, "related file from custom rule")
            end)
            acc ++ new_suggestions
          else
            acc
          end
          
        _ ->
          acc
      end
    end)
  end

  defp expand_file_pattern(file_pattern, reason) do
    if contains_glob?(file_pattern) do
      case Path.wildcard(file_pattern) do
        [] -> [{file_pattern, reason}]
        matched_files -> Enum.map(matched_files, &{&1, reason})
      end
    else
      [{file_pattern, reason}]
    end
  end

  defp contains_glob?(pattern) do
    String.contains?(pattern, "*") || String.contains?(pattern, "?") || 
    String.contains?(pattern, "[") || String.contains?(pattern, "{")
  end

  defp match_pattern?(file_path, pattern) do
    cond do
      contains_glob?(pattern) ->
        # Use our glob utility for pattern matching
        Claude.Utils.Glob.match?(file_path, pattern)
        
      true ->
        # Exact match or contains for non-glob patterns
        file_path == pattern || String.contains?(file_path, pattern)
    end
  end

  defp maybe_add(related, file, reason) do
    if Enum.any?(related, fn {f, _} -> f == file end) do
      related
    else
      [{file, reason} | related]
    end
  end
end