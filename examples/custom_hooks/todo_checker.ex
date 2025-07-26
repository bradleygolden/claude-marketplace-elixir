defmodule MyApp.Hooks.TodoChecker do
  @moduledoc """
  Example custom hook that checks for TODO/FIXME/HACK comments in edited files.
  
  This hook runs after file edits and warns about any TODO-style comments found.
  It can be configured via `.claude.exs` to customize the pattern and behavior.
  """

  @behaviour Claude.Hooks.Hook.Behaviour

  require Logger

  @impl true
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "mix claude hooks run post_tool_use.todo_checker",
      matcher: "Edit|MultiEdit|Write"
    }
  end

  @impl true
  def description do
    "Checks for TODO/FIXME/HACK comments in edited files"
  end

  @impl true
  def run(tool_name, json_params) do
    with {:ok, params} <- Jason.decode(json_params),
         file_path when is_binary(file_path) <- get_file_path(tool_name, params),
         true <- File.exists?(file_path),
         {:ok, content} <- File.read(file_path) do
      
      config = Claude.Hooks.Registry.hook_config(__MODULE__)
      pattern = Map.get(config, :todo_pattern, ~r/TODO|FIXME|HACK/)
      fail_on_todos = Map.get(config, :fail_on_todos, false)
      
      case Regex.scan(pattern, content) do
        [] ->
          :ok
          
        matches ->
          Logger.warning("Found #{length(matches)} TODO-style comments in #{file_path}")
          
          lines = String.split(content, "\n")
          
          Enum.each(matches, fn [match] ->
            line_number = find_line_number(lines, match)
            Logger.warning("  Line #{line_number}: #{match}")
          end)
          
          if fail_on_todos do
            {:error, "File contains TODO comments"}
          else
            :ok
          end
      end
    else
      _ -> :ok
    end
  end

  defp get_file_path("Write", %{"file_path" => path}), do: path
  defp get_file_path("Edit", %{"file_path" => path}), do: path
  defp get_file_path("MultiEdit", %{"file_path" => path}), do: path
  defp get_file_path(_, _), do: nil

  defp find_line_number(lines, match) do
    Enum.find_index(lines, fn line ->
      String.contains?(line, match)
    end)
    |> case do
      nil -> "?"
      index -> index + 1
    end
  end
end