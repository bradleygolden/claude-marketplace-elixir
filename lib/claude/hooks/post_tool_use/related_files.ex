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

  ## Custom Hook Implementation

  For more complex customization, you can create your own hook module:

      defmodule MyProject.Hooks.RelatedFiles do
        use Claude.Hook,
          event: :post_tool_use,
          matcher: [:write, :edit, :multi_edit],
          description: "Custom related files for MyProject"
        
        @impl true
        def handle(%Claude.Hooks.Events.PostToolUse.Input{} = input) do
          # Your custom logic here
          :ok
        end
      end
  """

  use Claude.Hook,
    event: :post_tool_use,
    matcher: [:write, :edit, :multi_edit],
    description: "Suggests updating related files based on naming patterns"

  alias Claude.Hooks.{Helpers, JsonOutput}

  @impl true
  def handle(%Claude.Hooks.Events.PostToolUse.Input{} = input) do
    if input.tool_name in ["Write", "Edit", "MultiEdit"] do
      case extract_file_path(input.tool_input) do
        {:ok, file_path} ->
          related_files = find_related_files(file_path)

          if related_files != [] do
            suggest_updates(file_path, related_files)
          else
            :ok
          end

        _ ->
          :ok
      end
    else
      :ok
    end
  end

  defp extract_file_path(tool_input) do
    Helpers.extract_file_path(tool_input)
  end

  defp find_related_files(file_path) do
    project_dir = Helpers.get_project_dir(file_path)

    relative_path = Path.relative_to(file_path, project_dir)

    default_patterns()
    |> Enum.flat_map(fn {source_glob, target_transform} ->
      if glob_match?(relative_path, source_glob) do
        target_transform
        |> List.wrap()
        |> Enum.flat_map(&transform_path(relative_path, source_glob, &1))
        |> Enum.map(&Path.join(project_dir, &1))
        |> Enum.filter(&File.exists?/1)
      else
        []
      end
    end)
    |> Enum.uniq()
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
      # ** can match zero or more subdirectories
      |> String.replace("/**", "(?:/.+)?")
      |> String.replace("*", "[^/]*")
      |> then(&"^#{&1}$")
      |> Regex.compile!()

    Regex.match?(regex_pattern, path)
  end

  defp default_patterns do
    [
      # When lib files change, suggest their tests
      {"lib/**/*.ex", "test/**/*_test.exs"},
      # When test files change, suggest their lib files
      {"test/**/*_test.exs", "lib/**/*.ex"}
    ]
  end

  defp suggest_updates(modified_file, related_files) do
    message = format_suggestion(modified_file, related_files)
    {:block, message}
  end

  defp format_suggestion(modified_file, related_files) do
    # Get the project directory to make paths relative for display
    project_dir = Helpers.get_project_dir(modified_file)

    # Make paths relative for cleaner display
    relative_modified = Path.relative_to(modified_file, project_dir)
    relative_files = Enum.map(related_files, &Path.relative_to(&1, project_dir))

    files_list = Enum.map_join(relative_files, "\n", &"  - #{&1}")

    """
    Related files need updating:

    You modified: #{relative_modified}

    Consider updating:
    #{files_list}
    """
  end
end
