defmodule Claude.Hooks.PostToolUse.ElixirFormatterTest do
  use ExUnit.Case, async: false

  alias Claude.Hooks.PostToolUse.ElixirFormatter

  @test_dir Path.join(System.tmp_dir!(), "claude_formatter_test_#{:erlang.phash2(make_ref())}")

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)
    original_cwd = File.cwd!()
    File.cd!(@test_dir)

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
      File.cd!(original_cwd)
      File.rm_rf!(@test_dir)
    end)

    {:ok, test_dir: @test_dir}
  end

  describe "process/2" do
    test "formats Elixir files when using Edit tool" do
      file_path = Path.join(@test_dir, "test.ex")

      File.write!(file_path, """
      defmodule Test do
      def hello(  x,y  ) do
        x+y
      end
      end
      """)

      json_params = Jason.encode!(%{"file_path" => file_path})

      assert :ok = ElixirFormatter.run("Edit", json_params)

      formatted_content = File.read!(file_path)
      assert formatted_content =~ "def hello(x, y) do"
      assert formatted_content =~ ~r/^\s+x \+ y$/m
    end

    test "formats .exs files" do
      file_path = Path.join(@test_dir, "test.exs")
      File.write!(file_path, "  list  = [ 1,2,  3 ]")

      json_params = Jason.encode!(%{"file_path" => file_path})

      assert :ok = ElixirFormatter.run("Write", json_params)

      assert File.read!(file_path) == "list = [1, 2, 3]\n"
    end

    test "works with MultiEdit tool" do
      file_path = Path.join(@test_dir, "multi.ex")
      File.write!(file_path, "defmodule  Multi  do\nend")

      json_params = Jason.encode!(%{"file_path" => file_path})

      assert :ok = ElixirFormatter.run("MultiEdit", json_params)

      assert File.read!(file_path) == "defmodule Multi do\nend\n"
    end

    test "ignores non-Elixir files" do
      file_path = Path.join(@test_dir, "test.js")
      original = "function  hello(  x  )  { return x; }"
      File.write!(file_path, original)

      json_params = Jason.encode!(%{"file_path" => file_path})

      assert :ok = ElixirFormatter.run("Edit", json_params)

      # Content should remain unchanged
      assert File.read!(file_path) == original
    end

    test "ignores non-edit tools" do
      file_path = Path.join(@test_dir, "read.ex")
      original = "defmodule  Read  do\nend"
      File.write!(file_path, original)

      json_params = Jason.encode!(%{"file_path" => file_path})

      assert :ok = ElixirFormatter.run("Read", json_params)

      # Content should remain unchanged
      assert File.read!(file_path) == original
    end

    test "handles missing file_path gracefully" do
      json_params = Jason.encode!(%{"other_param" => "value"})

      assert :ok = ElixirFormatter.run("Edit", json_params)
    end

    test "handles invalid JSON gracefully" do
      assert :ok = ElixirFormatter.run("Edit", "invalid json")
    end

    test "uses CLAUDE_PROJECT_DIR when available" do
      # Set CLAUDE_PROJECT_DIR
      System.put_env("CLAUDE_PROJECT_DIR", @test_dir)

      # Create file in a subdirectory
      File.mkdir_p!("lib")
      file_path = Path.join(@test_dir, "lib/test.ex")
      File.write!(file_path, "defmodule  Test  do\nend")

      json_params = Jason.encode!(%{"file_path" => file_path})

      assert :ok = ElixirFormatter.run("Edit", json_params)

      assert File.read!(file_path) == "defmodule Test do\nend\n"

      System.delete_env("CLAUDE_PROJECT_DIR")
    end
  end
end
