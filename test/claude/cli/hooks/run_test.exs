defmodule Claude.CLI.Hooks.RunTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO
  import Claude.TestHelpers

  alias Claude.CLI.Hooks.Run

  describe "run/1" do
    test "executes hook when valid identifier provided" do
      in_tmp(fn _tmp_dir ->
        File.mkdir_p!("lib")
        file_path = Path.join(File.cwd!(), "lib/test.ex")

        File.write!(file_path, """
        defmodule  Test  do
          def hello,  do:  :world
        end
        """)

        json_params = Jason.encode!(%{"file_path" => file_path})

        File.write!("mix.exs", """
        defmodule TestProject.MixProject do
          use Mix.Project
          def project, do: [app: :test_project, version: "0.1.0"]
        end
        """)

        File.write!(".formatter.exs", "[inputs: [\"**/*.{ex,exs}\"]]")

        output =
          capture_io(:stderr, fn ->
            assert :ok = Run.run(["post_tool_use.elixir_formatter", "Edit", json_params])
          end)

        content = File.read!(file_path)
        assert content =~ "defmodule  Test  do"
        assert content =~ "def hello,  do:  :world"

        assert output =~ "File needs formatting: #{file_path}"
      end)
    end

    test "returns ok when unknown hook identifier provided" do
      json_params = Jason.encode!(%{"file_path" => "test.ex"})

      output =
        capture_io(fn ->
          assert :ok = Run.run(["unknown.hook", "Edit", json_params])
        end)

      assert output == ""
    end

    test "handles invalid arguments gracefully" do
      assert :ok = Run.run([])
      assert :ok = Run.run(["only_one_arg"])
      assert :ok = Run.run(["two", "args"])
      assert :ok = Run.run(["too", "many", "args", "here"])
    end

    test "executes compilation checker hook" do
      in_tmp(fn _tmp_dir ->
        File.mkdir_p!("lib")
        file_path = Path.join(File.cwd!(), "lib/test.ex")

        File.write!(file_path, """
        defmodule Test do
          def hello do
            undefined_variable
          end
        end
        """)

        json_params = Jason.encode!(%{"file_path" => file_path})

        File.write!("mix.exs", """
        defmodule TestProject.MixProject do
          use Mix.Project
          def project, do: [app: :test_project, version: "0.1.0"]
        end
        """)

        System.put_env("CLAUDE_PROJECT_DIR", File.cwd!())

        output =
          capture_stderr(fn ->
            assert :ok = Run.run(["post_tool_use.compilation_checker", "Edit", json_params])
          end)

        assert output =~ "Compilation issues detected"
        assert output =~ "undefined_variable"

        System.delete_env("CLAUDE_PROJECT_DIR")
      end)
    end

    test "handles malformed JSON gracefully" do
      assert :ok = Run.run(["post_tool_use.elixir_formatter", "Edit", "not json"])
    end
  end

  defp capture_stderr(fun) do
    ExUnit.CaptureIO.capture_io(:stderr, fun)
  end
end
