defmodule Claude.Hooks.PostToolUse.ElixirFormatterTest do
  use Claude.Test.ClaudeCodeCase, async: false
  import Claude.Test.HookTestHelpers

  alias Claude.Hooks.PostToolUse.ElixirFormatter

  setup do
    {test_dir, cleanup} = setup_hook_test(
      files: %{
        ".formatter.exs" => "[inputs: [\"**/*.{ex,exs}\"]]"
      }
    )
    on_exit(cleanup)
    {:ok, test_dir: test_dir}
  end

  describe "run/1" do
    test "checks formatting for Elixir files when using Edit tool", %{test_dir: test_dir} do
      unformatted_content = """
      defmodule Test do
      def hello(  x,y  ) do
        x+y
      end
      end
      """

      file_path = create_elixir_file(test_dir, "test.ex", unformatted_content)
      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run(stdin_json)
      end)

      assert File.read!(file_path) == unformatted_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "checks formatting for .exs files", %{test_dir: test_dir} do
      unformatted_content = "  list  = [ 1,2,  3 ]"
      file_path = create_elixir_file(test_dir, "test.exs", unformatted_content)
      stdin_json = build_tool_input(tool_name: "Write", file_path: file_path)

      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run(stdin_json)
      end)

      assert File.read!(file_path) == unformatted_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "works with MultiEdit tool", %{test_dir: test_dir} do
      unformatted_content = "defmodule  Multi  do\nend"
      file_path = create_elixir_file(test_dir, "multi.ex", unformatted_content)
      stdin_json = build_tool_input(tool_name: "MultiEdit", file_path: file_path)

      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run(stdin_json)
      end)

      assert File.read!(file_path) == unformatted_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "does not show warning for properly formatted files", %{test_dir: test_dir} do
      properly_formatted = """
      defmodule Formatted do
        def hello(x, y) do
          x + y
        end
      end
      """

      file_path = create_elixir_file(test_dir, "formatted.ex", properly_formatted)
      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run(stdin_json)
      end)

      assert File.read!(file_path) == properly_formatted
      refute output =~ "File needs formatting"
      assert output == ""
    end

    test "ignores non-Elixir files", %{test_dir: test_dir} do
      file_path = Path.join(test_dir, "test.js")
      content = "function  hello(  x  )  { return x; }"
      File.write!(file_path, content)
      
      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      assert :ok = ElixirFormatter.run(stdin_json)
      assert File.read!(file_path) == content
    end

    test "ignores non-edit tools", %{test_dir: test_dir} do
      unformatted_content = "defmodule  Read  do\nend"
      file_path = create_elixir_file(test_dir, "read.ex", unformatted_content)
      stdin_json = build_tool_input(tool_name: "Read", file_path: file_path)

      assert :ok = ElixirFormatter.run(stdin_json)
      assert File.read!(file_path) == unformatted_content
    end

    test "handles missing file_path in tool_input gracefully" do
      stdin_json = Jason.encode!(%{
        "tool_name" => "Edit",
        "tool_input" => %{"other_param" => "value"}
      })

      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run(stdin_json)
      end)

      assert output == ""
    end

    test "handles invalid JSON input gracefully" do
      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run("invalid json")
      end)

      assert output == ""
    end

    test "handles :eof input gracefully" do
      assert :ok = ElixirFormatter.run(:eof)
    end

    test "uses CLAUDE_PROJECT_DIR when available", %{test_dir: test_dir} do
      # CLAUDE_PROJECT_DIR is already set by setup_hook_test
      unformatted_content = "defmodule  Test  do\nend"
      file_path = create_elixir_file(test_dir, "lib/test.ex", unformatted_content)
      stdin_json = build_tool_input(tool_name: "Edit", file_path: file_path)

      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run(stdin_json)
      end)

      assert File.read!(file_path) == unformatted_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "handles empty tool_input gracefully", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "test.ex", """
      defmodule  Test  do
        def hello,  do:  :world
      end
      """)

      stdin_json = Jason.encode!(%{
        "tool_name" => "Edit",
        "tool_input" => %{}
      })

      output = capture_stderr(fn ->
        assert :ok = ElixirFormatter.run(stdin_json)
      end)

      assert output == ""
    end
  end
end
