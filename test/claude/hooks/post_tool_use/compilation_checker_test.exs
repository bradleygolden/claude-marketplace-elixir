defmodule Claude.Hooks.PostToolUse.CompilationCheckerTest do
  use Claude.ClaudeCodeCase, setup_project?: true

  alias Claude.Hooks.PostToolUse.CompilationChecker
  alias Claude.Test.Fixtures
  import Claude.Test.HookTestHelpers

  describe "run/1" do
    test "passes when Elixir file compiles successfully", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/test.ex", """
        defmodule LibTest do
          def hello, do: :world
        end
        """)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path),
          cwd: test_dir
        )

      assert_hook_success(CompilationChecker, input)
    end

    test "reports compilation errors", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/test.ex", """
        defmodule TestModule do
          def hello(name) do
            "Hello, \#{undefined_var}!"
          end
        end
        """)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path),
          cwd: test_dir
        )

      stderr = assert_hook_error(CompilationChecker, input)
      assert stderr =~ "Compilation issues detected"
      assert stderr =~ "undefined variable"
    end

    test "reports warnings as errors", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/test.ex", """
        defmodule Test do
          def hello do
            unused = 42
            :world
          end
        end
        """)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input: Fixtures.tool_input(:write, file_path: file_path),
          cwd: test_dir
        )

      stderr = assert_hook_error(CompilationChecker, input)
      assert stderr =~ "Compilation issues detected"
      assert stderr =~ "variable \"unused\" is unused"
    end

    test "ignores non-Elixir files" do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: "/path/to/file.txt"),
          cwd: "."
        )

      assert_hook_success(CompilationChecker, input)
    end

    test "ignores non-edit tools" do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Read",
          tool_input: %{file_path: "/path/to/file.ex"},
          cwd: "."
        )

      assert_hook_success(CompilationChecker, input)
    end

    test "handles missing file_path gracefully" do
      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: %{},
          cwd: "."
        )

      assert_hook_success(CompilationChecker, input)
    end

    test "handles invalid JSON input gracefully" do
      # For invalid JSON, we expect the hook to exit with code 0 (error handling)
      assert_hook_success(CompilationChecker, "invalid json")
    end

    test "handles :eof input gracefully" do
      # Direct call to run with :eof should not crash
      # Since we can't easily test System.halt with :eof, we'll use pattern matching
      assert CompilationChecker.run(:eof) == :ok
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

      assert_hook_success(CompilationChecker, input)
    end
  end
end
