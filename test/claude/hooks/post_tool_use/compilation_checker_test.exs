defmodule Claude.Hooks.PostToolUse.CompilationCheckerTest do
  use Claude.ClaudeCodeCase, async: true, setup_project?: true

  alias Claude.Hooks.PostToolUse.CompilationChecker
  alias Claude.Test.Fixtures

  describe "run/1" do
    test "passes when Elixir file compiles successfully", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/test.ex", """
        defmodule LibTest do
          def hello, do: :world
        end
        """)

      json =
        run_hook(
          CompilationChecker,
          Fixtures.post_tool_use_input(
            tool_name: "Edit",
            tool_input: Fixtures.tool_input(:edit, file_path: file_path)
          )
        )

      assert json["continue"] == true
      assert json["suppressOutput"] == true
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

      json =
        run_hook(
          CompilationChecker,
          Fixtures.post_tool_use_input(
            tool_name: "Edit",
            tool_input: Fixtures.tool_input(:edit, file_path: file_path)
          )
        )

      assert json["decision"] == "block"
      assert json["reason"] =~ "Compilation issues detected"
      assert json["reason"] =~ "undefined variable"
    end

    test "reports warnings as errors", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/test.ex", """
        defmodule TestModule do
          def hello(name) do
            unused = 42
            "Hello, \#{name}!"
          end
        end
        """)

      json =
        run_hook(
          CompilationChecker,
          Fixtures.post_tool_use_input(
            tool_name: "Edit",
            tool_input: Fixtures.tool_input(:edit, file_path: file_path)
          )
        )

      assert json["decision"] == "block"
      assert json["reason"] =~ "Compilation issues detected"
      assert json["reason"] =~ "unused"
    end

    test "works with .exs files", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "test.exs", """
        IO.puts("Hello, World!")
        """)

      json =
        run_hook(
          CompilationChecker,
          Fixtures.post_tool_use_input(
            tool_name: "Write",
            tool_input: Fixtures.tool_input(:write, file_path: file_path)
          )
        )

      assert json["continue"] == true
      assert json["suppressOutput"] == true
    end

    test "works with MultiEdit tool", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/multi.ex", """
        defmodule Multi do
          def test, do: :ok
        end
        """)

      json =
        run_hook(
          CompilationChecker,
          Fixtures.post_tool_use_input(
            tool_name: "MultiEdit",
            tool_input: Fixtures.tool_input(:multi_edit, file_path: file_path)
          )
        )

      assert json["continue"] == true
      assert json["suppressOutput"] == true
    end

    test "ignores non-Elixir files", %{test_dir: test_dir} do
      file_path = Path.join(test_dir, "test.js")
      File.write!(file_path, "console.log('hello');")

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path)
        )

      json = run_hook(CompilationChecker, input)
      assert json["suppressOutput"] == true
    end

    test "handles missing file_path in tool_input gracefully" do
      input_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"other_param" => "value"}
        })

      json = run_hook(CompilationChecker, input_json)
      assert json["suppressOutput"] == true
    end

    test "handles invalid JSON input gracefully" do
      json = run_hook(CompilationChecker, "invalid json")
      assert json["decision"] == "block"
      assert json["reason"] =~ "Hook crashed"
      assert json["suppressOutput"] == false
    end

    test "handles :eof input gracefully" do
      assert :ok = CompilationChecker.run(:eof)
    end

    test "uses CLAUDE_PROJECT_DIR when available", %{test_dir: test_dir} do
      file_path =
        create_file(test_dir, "lib/subdir/test.ex", """
        defmodule SubdirTest do
          def test, do: :ok
        end
        """)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path)
        )

      json = run_hook(CompilationChecker, input)
      assert json["suppressOutput"] == true
    end
  end
end
