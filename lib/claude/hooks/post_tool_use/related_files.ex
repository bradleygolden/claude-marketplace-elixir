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
              
              # When controller files change, suggest updating multiple related files
              {"lib/myapp_web/controllers/*_controller.ex",
               ["lib/myapp_web/views/*_view.ex", "lib/myapp_web/templates/*/*.html.heex"]},
              
              # Glob patterns support standard wildcards
              {"lib/myapp/schemas/*.ex",
               ["test/myapp/schemas/*_test.exs", "test/factories/*_factory.ex"]}
            ]
          }}
        ]
      }

  ### Available Options

  - `:patterns` - A list of `{source_glob, target_globs}` tuples where:
    - `source_glob` is a glob pattern to match modified files
    - `target_globs` is either a single glob pattern or a list of glob patterns
    - Both source and target patterns are relative to the project root

  ## Pattern Format

  Patterns use standard glob syntax:
  - `*` matches any sequence of characters within a single path segment
  - `**` matches any sequence of path segments (including none)
  - `?` matches any single character
  - `[abc]` matches any character in the set
  - `{foo,bar}` matches either "foo" or "bar"

  When a file is modified:
  1. The file path is checked against each source glob pattern
  2. If it matches, all files matching the target glob patterns are suggested

  ## Default Behavior

  If no configuration is provided, the hook uses built-in patterns that map:
  - `lib/**/*.ex` files to their corresponding `test/**/*_test.exs` files
  - `test/**/*_test.exs` files back to their `lib/**/*.ex` files

  ## Customization via Subclassing

  For more complex customization, you can create your own hook module:

      defmodule MyProject.Hooks.RelatedFiles do
        use Claude.Hooks.Hook.Behaviour,
          event: :post_tool_use,
          matcher: [:write, :edit, :multi_edit],
          description: "Custom related files for MyProject"

        # Copy the implementation from Claude.Hooks.PostToolUse.RelatedFiles
        # and override default_patterns/0
      end
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:write, :edit, :multi_edit],
    description: "Suggests updating related files based on naming patterns"

  alias Claude.Hooks.{Helpers, JsonOutput}

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof), do: :ok

  def run(json_input) when is_binary(json_input) do
    case Claude.Hooks.Events.PostToolUse.Input.from_json(json_input) do
      {:ok, %Claude.Hooks.Events.PostToolUse.Input{} = input} ->
        process_file_change(input)

      {:error, _} ->
        JsonOutput.success(suppress_output: true)
        |> JsonOutput.write_and_exit()
    end
  end

  @impl Claude.Hooks.Hook.Behaviour
  def run(json_input, _user_config) when is_binary(json_input) do
    run(json_input)
  end

  defp process_file_change(input) do
    with :ok <- validate_tool(input.tool_name),
         {:ok, file_path} <- extract_file_path(input.tool_input) do
      related_files = find_related_files(file_path)

      if related_files != [] do
        suggest_updates(file_path, related_files)
      else
        JsonOutput.success(suppress_output: true)
        |> JsonOutput.write_and_exit()
      end
    else
      _ ->
        JsonOutput.success(suppress_output: true)
        |> JsonOutput.write_and_exit()
    end
  end

  defp validate_tool(tool_name) do
    if tool_name in Helpers.edit_tools() do
      :ok
    else
      {:skip, :not_edit_tool}
    end
  end

  defp extract_file_path(tool_input) do
    Helpers.extract_file_path(tool_input)
  end

  defp find_related_files(file_path) do
    default_patterns()
    |> Enum.flat_map(fn {source_glob, target_transform} ->
      if glob_match?(file_path, source_glob) do
        target_transform
        |> List.wrap()
        |> Enum.flat_map(&transform_path(file_path, source_glob, &1))
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
        Path.wildcard(target_pattern)
    end
  end

  defp glob_match?(path, pattern) do
    relative_path = Path.relative_to_cwd(path)

    regex_pattern =
      pattern
      |> String.replace(".", "\\.")
      |> String.replace("?", ".")
      |> handle_double_star()
      |> String.replace("*", "[^/]*")
      |> then(&"^#{&1}$")

    case Regex.compile(regex_pattern) do
      {:ok, regex} ->
        Regex.match?(regex, path) or Regex.match?(regex, relative_path)

      {:error, _} ->
        false
    end
  end

  defp handle_double_star(pattern) do
    pattern
    |> String.replace("/**/", "(?:/.*/|/)")
    |> String.replace("/**", "(?:/.*)?")
    |> String.replace("**/", "(?:.*/)?")
  end

  defp suggest_updates(modified_file, related_files) do
    message = build_feedback_message(modified_file, related_files)

    JsonOutput.block_post_tool(message)
    |> JsonOutput.write_and_exit()
  end

  defp build_feedback_message(modified_file, related_files) do
    files_list =
      related_files
      |> Enum.map(&"  - #{&1}")
      |> Enum.join("\n")

    """
    ❗ Related files need updating:

    You modified: #{modified_file}

    Please also review and decide whether to update these related files:
    #{files_list}

    Ensure these files reflect any changes to:
    - Function signatures
    - Module names
    - New functions or modules added
    - Functions or modules removed
    - Behavioral changes
    - Type specs or documentation
    """
  end

  defp default_patterns do
    [
      # Basic lib -> test mapping
      {"lib/**/*.ex", "test/**/*_test.exs"},

      # Test -> lib mapping (reverse)
      {"test/**/*_test.exs", "lib/**/*.ex"}
    ]
  end
end
