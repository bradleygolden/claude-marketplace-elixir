defmodule MyApp.Hooks.CopyrightHeader do
  @moduledoc """
  Example custom hook that ensures copyright headers are present in new files.
  
  This hook runs after file writes and adds a copyright header if missing.
  It can be configured via `.claude.exs` to customize the copyright text and file patterns.
  """

  @behaviour Claude.Hooks.Hook.Behaviour

  require Logger

  @impl true
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "mix claude hooks run post_tool_use.copyright_header",
      matcher: "Write"
    }
  end

  @impl true
  def description do
    "Ensures copyright headers are present in new source files"
  end

  @impl true
  def run(tool_name, json_params) do
    with {:ok, params} <- Jason.decode(json_params),
         file_path when is_binary(file_path) <- params["file_path"],
         true <- should_process_file?(file_path),
         {:ok, content} <- File.read(file_path),
         false <- has_copyright_header?(content) do
      
      config = Claude.Hooks.Registry.hook_config(__MODULE__)
      copyright_text = Map.get(config, :copyright_text, default_copyright())
      
      updated_content = add_copyright_header(file_path, content, copyright_text)
      
      case File.write(file_path, updated_content) do
        :ok ->
          Logger.info("Added copyright header to #{file_path}")
          :ok
          
        {:error, reason} ->
          Logger.error("Failed to add copyright header: #{inspect(reason)}")
          {:error, reason}
      end
    else
      _ -> :ok
    end
  end

  defp should_process_file?(file_path) do
    config = Claude.Hooks.Registry.hook_config(__MODULE__)
    patterns = Map.get(config, :file_patterns, default_patterns())
    
    Enum.any?(patterns, fn pattern ->
      match_pattern?(file_path, pattern)
    end)
  end

  defp match_pattern?(file_path, pattern) do
    regex_pattern = 
      pattern
      |> String.replace("**", ".*")
      |> String.replace("*", "[^/]*")
      |> Regex.compile!()
    
    Regex.match?(regex_pattern, file_path)
  end

  defp has_copyright_header?(content) do
    String.contains?(content, "Copyright") || 
    String.contains?(content, "copyright") ||
    String.contains?(content, "©")
  end

  defp add_copyright_header(file_path, content, copyright_text) do
    cond do
      String.ends_with?(file_path, ".ex") || String.ends_with?(file_path, ".exs") ->
        add_elixir_header(content, copyright_text)
        
      String.ends_with?(file_path, ".js") || String.ends_with?(file_path, ".ts") ->
        add_javascript_header(content, copyright_text)
        
      true ->
        content
    end
  end

  defp add_elixir_header(content, copyright_text) do
    header = """
    # #{copyright_text}
    # All rights reserved.

    """
    
    header <> content
  end

  defp add_javascript_header(content, copyright_text) do
    header = """
    /**
     * #{copyright_text}
     * All rights reserved.
     */

    """
    
    header <> content
  end

  defp default_copyright do
    year = Date.utc_today().year
    "Copyright (c) #{year}"
  end

  defp default_patterns do
    ["lib/**/*.ex", "test/**/*.exs", "src/**/*.js", "src/**/*.ts"]
  end
end