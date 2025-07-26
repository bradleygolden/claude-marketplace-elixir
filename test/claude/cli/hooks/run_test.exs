defmodule Claude.CLI.Hooks.RunTest do
  use Claude.Test.ClaudeCodeCase, async: false

  import ExUnit.CaptureIO
  import Claude.TestHelpers

  alias Claude.CLI.Hooks.Run

  describe "run/1" do
    test "executes ElixirFormatter hook with valid stdin JSON" do
      in_tmp(fn _tmp_dir ->
        setup_test_project()

        file_path = Path.join(File.cwd!(), "lib/test.ex")

        File.write!(file_path, """
        defmodule  Test  do
          def hello,  do:  :world
        end
        """)

        stdin_json =
          Jason.encode!(%{
            "tool_name" => "Edit",
            "tool_input" => %{"file_path" => file_path}
          })

        output =
          capture_io([input: stdin_json, capture_prompt: false], fn ->
            stderr =
              capture_io(:stderr, fn ->
                assert :ok = Run.run(["post_tool_use.elixir_formatter"])
              end)

            assert stderr =~ "File needs formatting: #{file_path}"
          end)

        assert output == ""
      end)
    end

    test "returns :ok when unknown hook identifier provided" do
      stdin_json =
        Jason.encode!(%{
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => "test.ex"}
        })

      output =
        capture_io([input: stdin_json, capture_prompt: false], fn ->
          stderr =
            capture_io(:stderr, fn ->
              assert :ok = Run.run(["unknown.hook"])
            end)

          assert stderr == ""
        end)

      assert output == ""
    end

    test "returns :ok with no arguments" do
      assert :ok = Run.run([])
    end

    test "returns :ok with multiple arguments" do
      assert :ok = Run.run(["arg1", "arg2"])
      assert :ok = Run.run(["arg1", "arg2", "arg3"])
    end

    test "handles empty stdin gracefully" do
      output =
        capture_io([input: "", capture_prompt: false], fn ->
          stderr =
            capture_io(:stderr, fn ->
              assert :ok = Run.run(["post_tool_use.elixir_formatter"])
            end)

          assert stderr == ""
        end)

      assert output == ""
    end

    test "executes CompilationChecker hook with compilation errors" do
      in_tmp(fn _tmp_dir ->
        setup_test_project()

        file_path = Path.join(File.cwd!(), "lib/test.ex")

        File.write!(file_path, """
        defmodule Test do
          def hello do
            undefined_variable
          end
        end
        """)

        stdin_json =
          Jason.encode!(%{
            "tool_name" => "Edit",
            "tool_input" => %{"file_path" => file_path}
          })

        output =
          capture_io([input: stdin_json, capture_prompt: false], fn ->
            stderr =
              capture_io(:stderr, fn ->
                assert :ok = Run.run(["post_tool_use.compilation_checker"])
              end)

            assert stderr =~ "Compilation issues detected"
            assert stderr =~ "undefined_variable"
          end)

        assert output == ""
      end)
    end

    test "handles malformed JSON input gracefully" do
      output =
        capture_io([input: "not json", capture_prompt: false], fn ->
          stderr =
            capture_io(:stderr, fn ->
              assert :ok = Run.run(["post_tool_use.elixir_formatter"])
            end)

          assert stderr == ""
        end)

      assert output == ""
    end

    test "executes PreCommitCheck hook for non-commit commands" do
      expect(System, :halt, fn 0 -> :ok end)

      in_tmp(fn _tmp_dir ->
        setup_test_project()

        stdin_json =
          Jason.encode!(%{
            "tool_name" => "Bash",
            "tool_input" => %{"command" => "ls -la"}
          })

        output =
          capture_io([input: stdin_json, capture_prompt: false], fn ->
            stderr =
              capture_io(:stderr, fn ->
                assert :ok = Run.run(["pre_tool_use.pre_commit_check"])
              end)

            assert stderr == ""
          end)

        assert output == ""
      end)
    end

    test "PreCommitCheck hook blocks on validation failure" do
      stub(System, :halt, fn exit_code -> {:ok, exit_code} end)

      in_tmp(fn _tmp_dir ->
        setup_test_project()

        File.write!("lib/bad.ex", """
        defmodule Bad do
        def hello(  name  ) do
            "Hello!"
        end
        end
        """)

        stdin_json =
          Jason.encode!(%{
            "session_id" => "ghi789",
            "hook_event_name" => "PreToolUse",
            "tool_name" => "Bash",
            "tool_input" => %{"command" => "git commit -m 'test'"}
          })

        stdout =
          capture_io([input: stdin_json, capture_prompt: false], fn ->
            stderr =
              capture_io(:stderr, fn ->
                hook_module = Claude.Hooks.PreToolUse.PreCommitCheck
                assert {:ok, 2} = hook_module.run(stdin_json)
              end)

            assert stderr =~ "Formatting check failed!"
          end)

        assert stdout =~ "Pre-commit validation triggered"
      end)
    end

    test "hooks work with minimal Claude Code JSON structure" do
      in_tmp(fn _tmp_dir ->
        setup_test_project()

        file_path = Path.join(File.cwd!(), "lib/test.ex")

        File.write!(file_path, """
        defmodule  Test  do
          def hello,  do:  :world
        end
        """)

        stdin_json =
          Jason.encode!(%{
            "tool_name" => "Edit",
            "tool_input" => %{"file_path" => file_path}
          })

        output =
          capture_io([input: stdin_json, capture_prompt: false], fn ->
            stderr =
              capture_io(:stderr, fn ->
                assert :ok = Run.run(["post_tool_use.elixir_formatter"])
              end)

            assert stderr =~ "File needs formatting: #{file_path}"
          end)

        assert output == ""
      end)
    end
  end

  defp setup_test_project do
    System.put_env("CLAUDE_PROJECT_DIR", File.cwd!())

    File.mkdir_p!("lib")

    File.write!("mix.exs", """
    defmodule TestProject.MixProject do
      use Mix.Project
      def project, do: [app: :test_project, version: "0.1.0"]
    end
    """)

    File.write!(".formatter.exs", "[inputs: [\"**/*.{ex,exs}\"]]")

    on_exit(fn ->
      System.delete_env("CLAUDE_PROJECT_DIR")
    end)
  end
end
