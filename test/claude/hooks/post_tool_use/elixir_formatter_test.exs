defmodule Claude.Hooks.PostToolUse.ElixirFormatterTest do
  use Claude.ClaudeCodeCase, setup_project?: true

  alias Claude.Hooks.PostToolUse.ElixirFormatter
  alias Claude.Test.Fixtures
  import Claude.Test.HookTestHelpers

  describe "run/1" do
    test "passes when Elixir file is properly formatted", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/test.ex", """
        defmodule Test do
          def hello, do: :world
        end
        """)

      # Ensure the file is formatted
      System.cmd("mix", ["format", file_path], cd: test_dir)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path),
          cwd: test_dir
        )

      assert_hook_success(ElixirFormatter, input)
    end

    test "reports when Elixir file needs formatting", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/test.ex", """
        defmodule Test do
        def hello,do: :world
        end
        """)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input: Fixtures.tool_input(:write, file_path: file_path),
          cwd: test_dir
        )

      stderr = assert_hook_error(ElixirFormatter, input)
      assert stderr =~ "File needs formatting"
      assert stderr =~ file_path
      assert stderr =~ "mix format"
    end

    test "reports when .exs file needs formatting", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "test.exs", "  list  = [ 1,2,  3 ]")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input: Fixtures.tool_input(:write, file_path: file_path),
          cwd: test_dir
        )

      stderr = assert_hook_error(ElixirFormatter, input)
      assert stderr =~ "File needs formatting"
    end

    test "works with MultiEdit tool", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "multi.ex", "defmodule  Multi  do\nend")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "MultiEdit",
          tool_input: Fixtures.tool_input(:multi_edit, file_path: file_path),
          cwd: test_dir
        )

      stderr = assert_hook_error(ElixirFormatter, input)
      assert stderr =~ "File needs formatting"
    end

    test "ignores non-Elixir files" do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: "/path/to/file.txt"),
          cwd: "."
        )

      assert_hook_success(ElixirFormatter, input)
    end

    test "ignores non-edit tools" do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Read",
          tool_input: %{file_path: "/path/to/file.ex"},
          cwd: "."
        )

      assert_hook_success(ElixirFormatter, input)
    end

    test "handles missing file_path gracefully" do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: %{},
          cwd: "."
        )

      assert_hook_success(ElixirFormatter, input)
    end

    test "handles invalid JSON input gracefully" do
      assert_hook_success(ElixirFormatter, "invalid json")
    end

    test "handles :eof input gracefully" do
      assert ElixirFormatter.run(:eof) == :ok
    end

    test "uses CLAUDE_PROJECT_DIR when available", %{test_dir: test_dir} do
      # Create a nested project structure
      project_dir = Path.join(test_dir, "my_project")
      File.mkdir_p!(Path.join(project_dir, "lib"))

      file_path =
        create_file(project_dir, "lib/test.ex", """
        defmodule ProjectTest do
          def hello, do: :world
        end
        """)

      # Ensure it's formatted
      System.cmd("mix", ["format", file_path], cd: project_dir)

      # Stub CLAUDE_PROJECT_DIR for this test
      stub(System, :get_env, fn
        "CLAUDE_PROJECT_DIR" -> project_dir
        key -> System.get_env(key)
      end)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path),
          cwd: test_dir
        )

      assert_hook_success(ElixirFormatter, input)
    end

    test "handles formatting check failures gracefully", %{test_dir: test_dir} do
      # Create a file that will cause mix format to fail
      file_path = Path.join(test_dir, "invalid.ex")
      File.write!(file_path, "this is not valid elixir code at all!")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path),
          cwd: test_dir
        )

      stderr = assert_hook_error(ElixirFormatter, input)
      # When mix format fails on invalid syntax, it still reports "needs formatting"
      assert stderr =~ "File needs formatting"
    end
  end
end
