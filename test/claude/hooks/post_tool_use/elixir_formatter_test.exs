defmodule Claude.Hooks.PostToolUse.ElixirFormatterTest do
  use Claude.Test.ClaudeCodeCase, async: false

  alias Claude.Hooks.PostToolUse.ElixirFormatter

  @test_dir Path.join(System.tmp_dir!(), "claude_formatter_test_#{:erlang.phash2(make_ref())}")

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)
    original_cwd = File.cwd!()
    File.cd!(@test_dir)

    System.put_env("CLAUDE_PROJECT_DIR", @test_dir)

    File.write!("mix.exs", """
    defmodule TestProject.MixProject do
      use Mix.Project

      def project do
        [app: :test_project, version: "0.1.0"]
      end
    end
    """)

    File.write!(".formatter.exs", "[inputs: [\"**/*.{ex,exs}\"]]")

    on_exit(fn ->
      System.delete_env("CLAUDE_PROJECT_DIR")
      File.cd!(original_cwd)
      File.rm_rf!(@test_dir)
    end)

    {:ok, test_dir: @test_dir}
  end

  describe "run/1" do
    test "checks formatting for Elixir files when using Edit tool" do
      file_path = Path.join(@test_dir, "test.ex")

      original_content = """
      defmodule Test do
      def hello(  x,y  ) do
        x+y
      end
      end
      """

      File.write!(file_path, original_content)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run(stdin_json)
        end)

      assert File.read!(file_path) == original_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "checks formatting for .exs files" do
      file_path = Path.join(@test_dir, "test.exs")
      original_content = "  list  = [ 1,2,  3 ]"
      File.write!(file_path, original_content)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Write",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run(stdin_json)
        end)

      assert File.read!(file_path) == original_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "works with MultiEdit tool" do
      file_path = Path.join(@test_dir, "multi.ex")
      original_content = "defmodule  Multi  do\nend"
      File.write!(file_path, original_content)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "MultiEdit",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run(stdin_json)
        end)

      assert File.read!(file_path) == original_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "does not show warning for properly formatted files" do
      file_path = Path.join(@test_dir, "formatted.ex")

      properly_formatted = """
      defmodule Formatted do
        def hello(x, y) do
          x + y
        end
      end
      """

      File.write!(file_path, properly_formatted)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run(stdin_json)
        end)

      assert File.read!(file_path) == properly_formatted
      refute output =~ "File needs formatting"
      assert output == ""
    end

    test "ignores non-Elixir files" do
      file_path = Path.join(@test_dir, "test.js")
      original = "function  hello(  x  )  { return x; }"
      File.write!(file_path, original)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      assert :ok = ElixirFormatter.run(stdin_json)

      assert File.read!(file_path) == original
    end

    test "ignores non-edit tools" do
      file_path = Path.join(@test_dir, "read.ex")
      original = "defmodule  Read  do\nend"
      File.write!(file_path, original)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Read",
          "tool_input" => %{"file_path" => file_path}
        })

      assert :ok = ElixirFormatter.run(stdin_json)

      assert File.read!(file_path) == original
    end

    test "handles missing file_path in tool_input gracefully" do
      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"other_param" => "value"}
        })

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run(stdin_json)
        end)

      assert output == ""
    end

    test "handles invalid JSON input gracefully" do
      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run("invalid json")
        end)

      assert output == ""
    end

    test "handles :eof input gracefully" do
      assert :ok = ElixirFormatter.run(:eof)
    end

    test "uses CLAUDE_PROJECT_DIR when available" do
      System.put_env("CLAUDE_PROJECT_DIR", @test_dir)

      File.mkdir_p!("lib")
      file_path = Path.join(@test_dir, "lib/test.ex")
      original_content = "defmodule  Test  do\nend"
      File.write!(file_path, original_content)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run(stdin_json)
        end)

      assert File.read!(file_path) == original_content
      assert output =~ "File needs formatting: #{file_path}"
    end

    test "handles empty tool_input gracefully" do
      file_path = Path.join(@test_dir, "test.ex")

      File.write!(file_path, """
      defmodule  Test  do
        def hello,  do:  :world
      end
      """)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{}
        })

      output =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert :ok = ElixirFormatter.run(stdin_json)
        end)

      assert output == ""
    end
  end
end
