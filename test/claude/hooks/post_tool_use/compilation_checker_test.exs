defmodule Claude.Hooks.PostToolUse.CompilationCheckerTest do
  use Claude.Test.ClaudeCodeCase, async: false

  alias Claude.Hooks.PostToolUse.CompilationChecker

  @test_dir Path.join(System.tmp_dir!(), "claude_compilation_test_#{:erlang.phash2(make_ref())}")

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)
    original_cwd = File.cwd!()
    File.cd!(@test_dir)

    File.write!("mix.exs", """
    defmodule TestProject.MixProject do
      use Mix.Project

      def project do
        [app: :test_project, version: "0.1.0", elixir: "~> 1.18"]
      end
    end
    """)

    File.mkdir_p!("lib")

    System.cmd("mix", ["compile"], cd: @test_dir)

    System.put_env("CLAUDE_PROJECT_DIR", @test_dir)

    on_exit(fn ->
      System.delete_env("CLAUDE_PROJECT_DIR")
      File.cd!(original_cwd)
      File.rm_rf!(@test_dir)
    end)

    {:ok, test_dir: @test_dir}
  end

  describe "run/1" do
    test "passes when Elixir file compiles successfully" do
      file_path = Path.join(@test_dir, "lib/test.ex")

      File.write!(file_path, ~S"""
      defmodule Test do
        def hello(name) do
          "Hello, #{name}!"
        end
      end
      """)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      assert capture_io(:stderr, fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end

    test "reports compilation errors" do
      file_path = Path.join(@test_dir, "lib/test.ex")

      File.write!(file_path, ~S"""
      defmodule Test do
        def hello(name) do
          "Hello, #{nam}!"
        end
      end
      """)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        capture_io(:stderr, fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output =~ "Compilation issues detected"
      assert output =~ "undefined variable \"nam\""
    end

    test "reports warnings as errors" do
      file_path = Path.join(@test_dir, "lib/test.ex")

      File.write!(file_path, ~S"""
      defmodule Test do
        def hello(name) do
          unused = 42
          "Hello, #{name}!"
        end
      end
      """)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        capture_io(:stderr, fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output =~ "Compilation issues detected"
      assert output =~ "unused"
    end

    test "works with .exs files" do
      file_path = Path.join(@test_dir, "test.exs")

      File.write!(file_path, """
      IO.puts("Hello, World!")
      """)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Write",
          "tool_input" => %{"file_path" => file_path}
        })

      assert capture_io(:stderr, fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end

    test "works with MultiEdit tool" do
      file_path = Path.join(@test_dir, "lib/multi.ex")

      File.write!(file_path, """
      defmodule Multi do
        def test, do: :ok
      end
      """)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "MultiEdit",
          "tool_input" => %{"file_path" => file_path}
        })

      assert capture_io(:stderr, fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end

    test "ignores non-Elixir files" do
      file_path = Path.join(@test_dir, "test.js")
      File.write!(file_path, "console.log('hello');")

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        capture_io(:stderr, fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output == ""
    end

    test "ignores non-edit tools" do
      file_path = Path.join(@test_dir, "lib/read.ex")
      File.write!(file_path, "defmodule Read, do: def test, do: :ok")

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Read",
          "tool_input" => %{"file_path" => file_path}
        })

      output =
        capture_io(:stderr, fn ->
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
        capture_io(:stderr, fn ->
          assert :ok = CompilationChecker.run(stdin_json)
        end)

      assert output == ""
    end

    test "handles invalid JSON input gracefully" do
      output =
        capture_io(:stderr, fn ->
          assert :ok = CompilationChecker.run("invalid json")
        end)

      assert output == ""
    end

    test "handles :eof input gracefully" do
      assert :ok = CompilationChecker.run(:eof)
    end

    test "uses CLAUDE_PROJECT_DIR when available" do
      System.put_env("CLAUDE_PROJECT_DIR", @test_dir)

      File.mkdir_p!("lib/subdir")
      file_path = Path.join(@test_dir, "lib/subdir/test.ex")

      File.write!(file_path, """
      defmodule SubdirTest do
        def test, do: :ok
      end
      """)

      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => file_path}
        })

      assert capture_io(:stderr, fn ->
               assert :ok = CompilationChecker.run(stdin_json)
             end) == ""
    end
  end
end
