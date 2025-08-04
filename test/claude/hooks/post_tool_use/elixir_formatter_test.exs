defmodule Claude.Hooks.PostToolUse.ElixirFormatterTest do
  use Claude.ClaudeCodeCase, async: true, setup_project?: true

  alias Claude.Hooks.PostToolUse.ElixirFormatter
  alias Claude.Test.Fixtures

  describe "run/1" do
    test "blocks when Elixir file needs formatting using Edit tool", %{test_dir: test_dir} do
      unformatted_content = """
      defmodule Test do
      def hello(  x,y  ) do
        x+y
      end
      end
      """

      file_path = create_file(test_dir, "test.ex", unformatted_content)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path)
        )

      json = run_hook(ElixirFormatter, input)

      assert json["decision"] == "block"
      assert File.read!(file_path) == unformatted_content
      assert json["reason"] =~ "File needs formatting: #{file_path}"
      assert json["reason"] =~ "Run 'mix format #{file_path}' to fix"
    end

    test "blocks when .exs file needs formatting", %{test_dir: test_dir} do
      unformatted_content = "  list  = [ 1,2,  3 ]"
      file_path = create_file(test_dir, "test.exs", unformatted_content)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Write",
          tool_input: Fixtures.tool_input(:write, file_path: file_path)
        )

      json = run_hook(ElixirFormatter, input)

      assert json["decision"] == "block"
      assert File.read!(file_path) == unformatted_content
      assert json["reason"] =~ "File needs formatting: #{file_path}"
    end

    test "works with MultiEdit tool", %{test_dir: test_dir} do
      unformatted_content = "defmodule  Multi  do\nend"
      file_path = create_file(test_dir, "multi.ex", unformatted_content)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "MultiEdit",
          tool_input: Fixtures.tool_input(:multi_edit, file_path: file_path)
        )

      json = run_hook(ElixirFormatter, input)

      assert json["decision"] == "block"
      assert File.read!(file_path) == unformatted_content
      assert json["reason"] =~ "File needs formatting: #{file_path}"
    end

    test "succeeds silently for properly formatted files", %{test_dir: test_dir} do
      properly_formatted = """
      defmodule Formatted do
        def hello(x, y) do
          x + y
        end
      end
      """

      file_path = create_file(test_dir, "formatted.ex", properly_formatted)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path)
        )

      json = run_hook(ElixirFormatter, input)

      assert json["continue"] == true
      assert File.read!(file_path) == properly_formatted
      assert json["suppressOutput"] == true
    end

    test "ignores non-Elixir files", %{test_dir: test_dir} do
      file_path = Path.join(test_dir, "test.js")
      content = "function  hello(  x  )  { return x; }"
      File.write!(file_path, content)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path)
        )

      json = run_hook(ElixirFormatter, input)

      assert json["continue"] == true
      assert File.read!(file_path) == content
      assert json["suppressOutput"] == true
    end

    test "ignores non-edit tools", %{test_dir: test_dir} do
      unformatted_content = "defmodule  Read  do\nend"
      file_path = create_file(test_dir, "read.ex", unformatted_content)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Read",
          tool_input: Fixtures.tool_input(:read, file_path: file_path)
        )

      json = run_hook(ElixirFormatter, input)

      assert json["continue"] == true
      assert File.read!(file_path) == unformatted_content
      assert json["suppressOutput"] == true
    end

    test "handles missing file_path in tool_input gracefully" do
      input_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"other_param" => "value"}
        })

      json = run_hook(ElixirFormatter, input_json)

      assert json["continue"] == true
      assert json["suppressOutput"] == true
    end

    test "handles invalid JSON input gracefully" do
      json = run_hook(ElixirFormatter, "invalid json")
      assert json["decision"] == "block"
      assert json["reason"] =~ "Hook crashed"
      assert json["suppressOutput"] == false
    end

    test "handles :eof input gracefully" do
      assert :ok = ElixirFormatter.run(:eof)
    end

    test "uses CLAUDE_PROJECT_DIR when available", %{test_dir: test_dir} do
      unformatted_content = "defmodule  Test  do\nend"
      file_path = create_file(test_dir, "lib/test.ex", unformatted_content)

      input =
        Fixtures.post_tool_use_input(
          tool_name: "Edit",
          tool_input: Fixtures.tool_input(:edit, file_path: file_path)
        )

      json = run_hook(ElixirFormatter, input)

      assert json["decision"] == "block"
      assert File.read!(file_path) == unformatted_content
      assert json["reason"] =~ "File needs formatting: #{file_path}"
    end

    test "handles empty tool_input gracefully", %{test_dir: test_dir} do
      create_file(test_dir, "test.ex", """
      defmodule  Test  do
        def hello,  do:  :world
      end
      """)

      input_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{}
        })

      json = run_hook(ElixirFormatter, input_json)

      assert json["continue"] == true
      assert json["suppressOutput"] == true
    end
  end
end
