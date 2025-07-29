defmodule Claude.Hooks.PostToolUse.CompilationCheckerTest do
  use Claude.Test.ClaudeCodeCase, async: false
  import Claude.Test.HookTestHelpers

  alias Claude.Hooks.PostToolUse.CompilationChecker

  setup do
    {test_dir, cleanup} = setup_hook_test()
    on_exit(cleanup)
    {:ok, test_dir: test_dir}
  end

  describe "run/1" do
    test "passes when Elixir file compiles successfully", %{test_dir: test_dir} do
      file_path = create_elixir_file(test_dir, "lib/test.ex")
      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      assert capture_stderr(fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end

    test "reports compilation errors", %{test_dir: test_dir} do
      file_path =
        create_elixir_file(test_dir, "lib/test.ex", """
        defmodule TestModule do
          def hello(name) do
            "Hello, \#{undefined_var}!"
          end
        end
        """)

      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      output =
        capture_stderr(fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output =~ "Compilation issues detected"
      assert output =~ "undefined variable"
    end

    test "reports warnings as errors", %{test_dir: test_dir} do
      file_path =
        create_elixir_file(test_dir, "lib/test.ex", """
        defmodule TestModule do
          def hello(name) do
            unused = 42
            "Hello, \#{name}!"
          end
        end
        """)

      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      output =
        capture_stderr(fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output =~ "Compilation issues detected"
      assert output =~ "unused"
    end

    test "works with .exs files", %{test_dir: test_dir} do
      file_path =
        create_elixir_file(test_dir, "test.exs", """
        IO.puts("Hello, World!")
        """)

      stdin_json = build_tool_input(tool_name: "Write", file_path: file_path)

      assert capture_stderr(fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end

    test "works with MultiEdit tool", %{test_dir: test_dir} do
      file_path =
        create_elixir_file(test_dir, "lib/multi.ex", """
        defmodule Multi do
          def test, do: :ok
        end
        """)

      stdin_json = build_tool_input(tool_name: "MultiEdit", file_path: file_path)

      assert capture_stderr(fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end

    test "ignores non-Elixir files", %{test_dir: test_dir} do
      file_path = Path.join(test_dir, "test.js")
      File.write!(file_path, "console.log('hello');")

      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      output =
        capture_stderr(fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output == ""
    end

    test "ignores non-edit tools", %{test_dir: test_dir} do
      file_path =
        create_elixir_file(test_dir, "lib/read.ex", """
        defmodule Read do
          def test, do: :ok
        end
        """)

      stdin_json = build_tool_input(tool_name: "Read", file_path: file_path)

      output =
        capture_stderr(fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output == ""
    end

    test "handles missing file_path in tool_input gracefully" do
      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"other_param" => "value"}
        })

      output =
        capture_stderr(fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output == ""
    end

    test "handles invalid JSON input gracefully" do
      output =
        capture_stderr(fn ->
          assert :ok = CompilationChecker.run("invalid json")
        end)

      assert output == ""
    end

    test "handles :eof input gracefully" do
      assert :ok = CompilationChecker.run(:eof)
    end

    test "uses CLAUDE_PROJECT_DIR when available", %{test_dir: test_dir} do
      # CLAUDE_PROJECT_DIR is already set by setup_hook_test
      file_path =
        create_elixir_file(test_dir, "lib/subdir/test.ex", """
        defmodule SubdirTest do
          def test, do: :ok
        end
        """)

      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      assert capture_stderr(fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end
  end
end
