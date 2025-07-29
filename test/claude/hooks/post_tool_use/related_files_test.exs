defmodule Claude.Hooks.PostToolUse.RelatedFilesTest do
  use Claude.Test.ClaudeCodeCase
  import Claude.Test.SystemHaltHelpers
  import Claude.Test.HookTestHelpers

  alias Claude.Hooks.PostToolUse.RelatedFiles

  describe "run/1" do
    test "returns :ok for :eof input" do
      assert RelatedFiles.run(:eof) == :ok
    end

    test "returns :ok when JSON parsing fails" do
      assert RelatedFiles.run("invalid json") == :ok
    end

    test "returns :ok for non-edit tools" do
      json_input =
        build_tool_input(
          tool_name: "Read",
          file_path: "lib/example.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      assert RelatedFiles.run(json_input) == :ok
    end

    test "returns :ok when no related files exist" do
      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/nonexistent/deeply/nested/file.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      assert RelatedFiles.run(json_input) == :ok
    end

    test "exits with code 2 when related test file exists" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      # Create files with relative paths since RelatedFiles works with relative paths
      create_elixir_file(test_dir, "lib/example.ex", "defmodule Example do\nend")
      create_elixir_file(test_dir, "test/example_test.exs", "defmodule ExampleTest do\nend")

      # Use relative path for the hook input
      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/example.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect_halt(2)

      output =
        capture_stderr(fn ->
          assert {:halt, 2} = RelatedFiles.run(json_input)
        end)

      assert output =~ "Related files need updating"

      cleanup.()
    end

    test "suggests multiple related files when they exist" do
      {test_dir, cleanup} = setup_hook_test(compile: false)

      # Create files with relative paths since RelatedFiles works with relative paths
      create_elixir_file(test_dir, "lib/mymodule.ex", "defmodule MyModule do\nend")
      create_elixir_file(test_dir, "test/mymodule_test.exs", "defmodule MyModuleTest do\nend")

      # Use relative path for the hook input
      json_input =
        build_tool_input(
          tool_name: "Edit",
          file_path: "test/mymodule_test.exs",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      expect_halt(2)

      output =
        capture_stderr(fn ->
          assert {:halt, 2} = RelatedFiles.run(json_input)
        end)

      assert output =~ "Related files need updating"
      assert output =~ "lib/mymodule.ex"
      assert output =~ "You modified: test/mymodule_test.exs"

      cleanup.()
    end
  end

  describe "run/2" do
    test "ignores user config and calls run/1" do
      json_input =
        build_tool_input(
          tool_name: "Write",
          file_path: "lib/example.ex",
          extra: %{"hook_event_name" => "PostToolUse"}
        )

      user_config = %{patterns: [{"custom", "pattern"}]}

      assert RelatedFiles.run(json_input, user_config) == :ok
    end
  end
end
