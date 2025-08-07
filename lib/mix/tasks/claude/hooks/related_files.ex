defmodule Mix.Tasks.Claude.Hooks.RelatedFiles do
  @moduledoc """
  Suggests related files that might need updating based on file changes.

  This task analyzes file edits and suggests related files based on naming patterns.

  ## Usage

      mix claude.hooks.related_files

  The task reads the Claude event JSON from the process dictionary (when called
  from claude.hook) or from stdin (when called directly).
  """

  use Mix.Task

  @shortdoc "Suggests related files that might need updating"

  @related_patterns [
    # Implementation -> Test mapping
    {~r{^lib/(.+)\.ex$}, "test/\\1_test.exs"},
    {~r{^test/(.+)_test\.exs$}, "lib/\\1.ex"},

    # LiveView patterns
    {~r{^lib/(.+)_live\.ex$}, ["lib/\\1_live.html.heex", "test/\\1_live_test.exs"]},
    {~r{^lib/(.+)_component\.ex$}, ["test/\\1_component_test.exs"]},

    # Controller patterns
    {~r{^lib/(.+)_controller\.ex$},
     ["test/\\1_controller_test.exs", "lib/\\1_html.ex", "lib/\\1_json.ex"]},
    {~r{^lib/(.+)_html\.ex$}, ["lib/\\1_controller.ex", "lib/\\1_html/*.html.heex"]},

    # Schema/Context patterns
    {~r{^lib/(.+)/(.+)\.ex$}, :context_pattern},

    # Mix task patterns
    {~r{^lib/mix/tasks/(.+)\.ex$}, "test/mix/tasks/\\1_test.exs"},
    {~r{^test/mix/tasks/(.+)_test\.exs$}, "lib/mix/tasks/\\1.ex"}
  ]

  @impl Mix.Task
  def run(_args) do
    event_json = IO.read(:stdio, :eof)

    case Jason.decode(event_json) do
      {:ok, event} ->
        handle_event(event)

      {:error, _} ->
        IO.puts(:stderr, "Invalid JSON input")
        System.halt(1)
    end
  end

  defp handle_event(%{"tool_name" => tool_name, "tool_input" => tool_input})
       when tool_name in ["Write", "Edit", "MultiEdit"] do
    file_path = get_file_path(tool_input)

    if file_path && elixir_file?(file_path) do
      suggestions = find_related_files(file_path)

      if suggestions != [] do
        print_suggestions(file_path, suggestions)
      end
    end

    # Always exit 0 - this is informational only
    System.halt(0)
  end

  defp handle_event(_) do
    # Not a file edit, ignore
    System.halt(0)
  end

  defp get_file_path(%{"file_path" => path}), do: path
  defp get_file_path(%{"path" => path}), do: path
  defp get_file_path(_), do: nil

  defp elixir_file?(path) do
    String.ends_with?(path, ".ex") || String.ends_with?(path, ".exs")
  end

  defp find_related_files(file_path) do
    # Make path relative to project root
    relative_path = Path.relative_to_cwd(file_path)

    @related_patterns
    |> Enum.flat_map(fn
      {pattern, replacement} when is_binary(replacement) ->
        case Regex.run(pattern, relative_path) do
          nil -> []
          _matches -> [apply_replacement(relative_path, pattern, replacement)]
        end

      {pattern, replacements} when is_list(replacements) ->
        case Regex.run(pattern, relative_path) do
          nil -> []
          _matches -> Enum.map(replacements, &apply_replacement(relative_path, pattern, &1))
        end

      {pattern, :context_pattern} ->
        case Regex.run(pattern, relative_path) do
          nil ->
            []

          [_full, context, module] ->
            base = "#{context}/#{module}"

            [
              "test/#{base}_test.exs",
              "lib/#{context}.ex",
              "test/#{context}_test.exs"
            ]
        end
    end)
    |> Enum.filter(&File.exists?/1)
    |> Enum.uniq()
  end

  defp apply_replacement(path, pattern, replacement) do
    Regex.replace(pattern, path, replacement)
  end

  defp print_suggestions(file_path, suggestions) do
    IO.puts("Related files need updating:\n")
    IO.puts("You modified: #{file_path}\n")
    IO.puts("Consider updating:")

    Enum.each(suggestions, fn suggestion ->
      IO.puts("  - #{suggestion}")
    end)

    IO.puts("")
  end
end
