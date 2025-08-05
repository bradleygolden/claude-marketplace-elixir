defmodule Claude.Hooks.PostToolUse.RelatedFiles do
  @moduledoc """
  A hook that suggests updating related files when a file is modified.

  This is an optional hook that can be customized for your project's file structure.

  ## Installation

  Add to your `.claude.exs`:

      %{
        hooks: [
          Claude.Hooks.PostToolUse.RelatedFiles
        ]
      }

  ## Configuration Options

  You can pass configuration options when registering the hook:

      %{
        hooks: [
          {Claude.Hooks.PostToolUse.RelatedFiles, %{
            patterns: [
              # When any lib file changes, suggest updating its test
              {"lib/**/*.ex", "test/**/*_test.exs"},
              
              # When a specific file changes, suggest specific targets
              {"lib/myapp/user.ex", "test/myapp/user_test.exs"},
              
              # When controller changes, suggest view and template
              {"lib/myapp_web/controllers/*_controller.ex", [
                "lib/myapp_web/views/*_view.ex",
                "lib/myapp_web/templates/*/*.html.heex"
              ]},
              
              # Bidirectional - when test changes, suggest lib file
              {"test/**/*_test.exs", "lib/**/*.ex"}
            ]
          }}
        ]
      }

  ## How It Works

  This hook:
  1. Monitors file edit operations (Write, Edit, MultiEdit)
  2. Checks if the modified file matches any configured patterns
  3. Suggests related files that might need updates
  4. Outputs a reminder to Claude to consider updating those files

  ## Pattern Syntax

  Patterns support:
  - Glob patterns: `lib/**/*.ex` matches any .ex file under lib/
  - Direct paths: `lib/myapp/user.ex` matches exactly that file
  - Multiple targets: Use an array for the target to suggest multiple files

  ## Default Patterns

  By default, the hook suggests:
  - Test files when lib files are modified (lib/ -> test/)
  - Lib files when test files are modified (test/ -> lib/)

  """

  @doc """
  Pipeline-style related files checker for Claude Code hooks.

  Uses exit codes to communicate with Claude Code:
  - Exit 0: Success (no output or no related files)
  - Exit 2: Related files found (stderr shown to Claude)
  """
  def run(:eof), do: :ok

  def run(input) do
    input
    |> parse_input()
    |> validate_tool()
    |> extract_file_path()
    |> find_related_files()
    |> format_response()
    |> output_and_exit()
  end

  defp parse_input(input) do
    case Claude.Hooks.Events.PostToolUse.Input.from_json(input) do
      {:ok, event} ->
        {:ok, event}

      {:error, _} ->
        {:error, "Invalid JSON input"}
    end
  end

  defp validate_tool({:error, _} = error), do: error

  defp validate_tool({:ok, %Claude.Hooks.Events.PostToolUse.Input{tool_name: tool_name} = input})
       when tool_name in ["Write", "Edit", "MultiEdit"] do
    {:ok, input}
  end

  defp validate_tool({:ok, _}), do: {:skip, "Not an edit tool"}

  defp extract_file_path({:error, _} = error), do: error
  defp extract_file_path({:skip, _} = skip), do: skip

  defp extract_file_path(
         {:ok, %Claude.Hooks.Events.PostToolUse.Input{tool_input: tool_input} = input}
       ) do
    case tool_input do
      %{file_path: path} when is_binary(path) ->
        {:ok, input}

      _ ->
        {:skip, "No file path"}
    end
  end

  defp find_related_files({:error, _} = error), do: error
  defp find_related_files({:skip, _} = skip), do: skip

  defp find_related_files(
         {:ok, %Claude.Hooks.Events.PostToolUse.Input{cwd: cwd, tool_input: tool_input}}
       ) do
    file_path = tool_input.file_path
    relative_path = Path.relative_to(file_path, cwd)

    related =
      default_patterns()
      |> Enum.flat_map(fn {source_glob, target_transform} ->
        if glob_match?(relative_path, source_glob) do
          target_transform
          |> List.wrap()
          |> Enum.flat_map(&transform_path(relative_path, source_glob, &1))
          |> Enum.map(&Path.join(cwd, &1))
          |> Enum.filter(&File.exists?/1)
        else
          []
        end
      end)
      |> Enum.uniq()

    case related do
      [] -> :no_related_files
      files -> {:related_files_found, file_path, files, cwd}
    end
  end

  defp transform_path(file_path, source_glob, target_pattern) do
    cond do
      String.contains?(target_pattern, "*") == false ->
        [target_pattern]

      source_glob == "lib/**/*.ex" and target_pattern == "test/**/*_test.exs" ->
        transformed =
          if String.contains?(file_path, "/lib/") do
            file_path
            |> String.replace("/lib/", "/test/")
            |> String.replace_suffix(".ex", "_test.exs")
          else
            file_path
            |> String.replace_prefix("lib/", "test/")
            |> String.replace_suffix(".ex", "_test.exs")
          end

        [transformed]

      source_glob == "test/**/*_test.exs" and target_pattern == "lib/**/*.ex" ->
        transformed =
          if String.contains?(file_path, "/test/") do
            file_path
            |> String.replace("/test/", "/lib/")
            |> String.replace_suffix("_test.exs", ".ex")
          else
            file_path
            |> String.replace_prefix("test/", "lib/")
            |> String.replace_suffix("_test.exs", ".ex")
          end

        [transformed]

      true ->
        []
    end
  end

  defp glob_match?(path, pattern) do
    regex_pattern =
      pattern
      |> String.replace(".", "\\.")
      |> String.replace("/**", "(?:/.+)?")
      |> String.replace("*", "[^/]*")
      |> then(&"^#{&1}$")
      |> Regex.compile!()

    Regex.match?(regex_pattern, path)
  end

  defp default_patterns do
    [
      {"lib/**/*.ex", "test/**/*_test.exs"},
      {"test/**/*_test.exs", "lib/**/*.ex"}
    ]
  end

  defp format_response(:no_related_files), do: :no_related_files
  defp format_response({:skip, _}), do: :skip
  defp format_response({:error, _}), do: :error
  defp format_response({:related_files_found, _, _, _} = result), do: result

  defp output_and_exit(:no_related_files) do
    System.halt(0)
  end

  defp output_and_exit(:skip) do
    System.halt(0)
  end

  defp output_and_exit(:error) do
    System.halt(0)
  end

  defp output_and_exit({:related_files_found, modified_file, related_files, cwd}) do
    relative_modified = Path.relative_to(modified_file, cwd)
    relative_files = Enum.map(related_files, &Path.relative_to(&1, cwd))

    files_list = Enum.map_join(relative_files, "\n", &"  - #{&1}")

    IO.puts(:stderr, "Related files need updating:")
    IO.puts(:stderr, "")
    IO.puts(:stderr, "You modified: #{relative_modified}")
    IO.puts(:stderr, "")
    IO.puts(:stderr, "Consider updating:")
    IO.puts(:stderr, files_list)
    IO.puts(:stderr, "")

    System.halt(2)
  end
end
