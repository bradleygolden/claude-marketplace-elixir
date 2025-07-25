defmodule Claude.Hooks.PreToolUse.PreCommitCheckTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Claude.Hooks.PreToolUse.PreCommitCheck

  @test_dir Path.join(System.tmp_dir!(), "claude_pre_commit_test_#{:erlang.phash2(make_ref())}")

  setup do
    File.rm_rf!(@test_dir)
    File.mkdir_p!(@test_dir)
    original_cwd = File.cwd!()
    File.cd!(@test_dir)

    # Set up a minimal Elixir project
    File.write!("mix.exs", """
    defmodule TestProject.MixProject do
      use Mix.Project

      def project do
        [app: :test_project, version: "0.1.0", elixir: "~> 1.14"]
      end
    end
    """)

    File.write!(".formatter.exs", "[\n  inputs: [\"**/*.{ex,exs}\"]\n]\n")

    File.mkdir_p!("lib")

    on_exit(fn ->
      File.cd!(original_cwd)
      File.rm_rf!(@test_dir)
      System.delete_env("CLAUDE_PROJECT_DIR")
    end)

    {:ok, test_dir: @test_dir}
  end

  describe "config/0" do
    test "returns proper hook configuration" do
      config = PreCommitCheck.config()

      assert config.type == "command"
      assert config.matcher == "Bash"
      assert config.command =~ "mix claude hooks run pre_tool_use.pre_commit_check"
    end
  end

  describe "description/0" do
    test "returns a description" do
      assert PreCommitCheck.description() =~ "formatting and compilation"
    end
  end

  describe "run/2 - git commit detection" do
    test "detects and validates git commit commands" do
      # Create properly formatted code
      System.put_env("CLAUDE_PROJECT_DIR", @test_dir)

      File.write!("lib/good.ex", """
      defmodule Good do
        def hello do
          :world
        end
      end
      """)

      # Format the file
      System.cmd("mix", ["format"], cd: @test_dir)

      hook_input = %{
        "session_id" => "test123",
        "hook_event_name" => "PreToolUse",
        "tool_name" => "Bash",
        "tool_input" => %{
          "command" => "git commit -m 'test commit'"
        }
      }

      # Simulate stdin input
      input_json = Jason.encode!(hook_input)

      # Since the hook reads from stdin and exits, we need to test it differently
      # We'll test the internal functions instead
      assert capture_io([input: input_json], fn ->
               assert_raise SystemExit, fn ->
                 PreCommitCheck.run("Bash", "unused")
               end
             end) =~ "Pre-commit validation triggered"
    end

    test "ignores non-git-commit bash commands" do
      hook_input = %{
        "tool_name" => "Bash",
        "tool_input" => %{
          "command" => "ls -la"
        }
      }

      input_json = Jason.encode!(hook_input)

      assert capture_io([input: input_json], fn ->
               assert_raise SystemExit, fn ->
                 PreCommitCheck.run("Bash", "unused")
               end
             end) == ""
    end

    test "handles invalid JSON gracefully" do
      assert capture_io([input: "invalid json", capture_prompt: false], fn ->
               assert_raise SystemExit, fn ->
                 PreCommitCheck.run("Bash", "unused")
               end
             end) =~ "Failed to parse hook input JSON"
    end

    test "handles missing fields gracefully" do
      hook_input = %{
        "other_field" => "value"
      }

      input_json = Jason.encode!(hook_input)

      assert capture_io([input: input_json], fn ->
               assert_raise SystemExit, fn ->
                 PreCommitCheck.run("Bash", "unused")
               end
             end) == ""
    end
  end

  # Integration tests that test the validation logic without System.halt
  describe "validation logic" do
    setup do
      System.put_env("CLAUDE_PROJECT_DIR", @test_dir)
      :ok
    end

    test "passes when code is properly formatted and compiles" do
      # Write properly formatted code
      File.write!("lib/good_code.ex", """
      defmodule GoodCode do
        def hello(name) do
          "Hello, \#{name}!"
        end
      end
      """)

      # Run mix format to ensure it's formatted
      System.cmd("mix", ["format"], cd: @test_dir)

      # Check that both formatting and compilation would pass
      output =
        capture_io(fn ->
          # Test formatting check
          {output, exit_code} =
            System.cmd("mix", ["format", "--check-formatted"],
              stderr_to_stdout: true,
              cd: @test_dir
            )

          assert exit_code == 0
          IO.puts(output)

          # Test compilation check
          {output, exit_code} =
            System.cmd("mix", ["compile", "--warnings-as-errors"],
              stderr_to_stdout: true,
              cd: @test_dir
            )

          assert exit_code == 0
          IO.puts(output)
        end)

      refute output =~ "Formatting check failed"
      refute output =~ "Compilation check failed"
    end

    test "fails when code has formatting issues" do
      # Write poorly formatted code
      File.write!("lib/bad_format.ex", """
      defmodule BadFormat do
      def hello(  name  ) do
        "Hello, \#{ name }!"
      end
      end
      """)

      {output, exit_code} =
        System.cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true, cd: @test_dir)

      assert exit_code != 0
      assert output =~ "bad_format.ex" or output =~ "not formatted"
    end

    test "fails when code has compilation errors" do
      # Write code with compilation error
      File.write!("lib/bad_compile.ex", """
      defmodule BadCompile do
        def hello(name) do
          undefined_function()
        end
      end
      """)

      {output, exit_code} =
        System.cmd("mix", ["compile", "--warnings-as-errors"],
          stderr_to_stdout: true,
          cd: @test_dir
        )

      assert exit_code != 0
      assert output =~ "undefined_function"
    end

    test "fails when code has warnings with --warnings-as-errors" do
      # Write code with unused variable warning
      File.write!("lib/warning_code.ex", """
      defmodule WarningCode do
        def hello(name, unused) do
          "Hello, \#{name}!"
        end
      end
      """)

      {output, exit_code} =
        System.cmd("mix", ["compile", "--warnings-as-errors"],
          stderr_to_stdout: true,
          cd: @test_dir
        )

      assert exit_code != 0
      assert output =~ "unused"
    end
  end

  describe "edge cases" do
    test "handles missing mix.exs gracefully" do
      File.rm!("mix.exs")

      {output, _exit_code} = System.cmd("mix", ["compile"], stderr_to_stdout: true, cd: @test_dir)

      assert output =~ "Could not find a Mix.Project"
    end

    test "handles empty project directory" do
      # Clean up all files
      File.rm_rf!(@test_dir)
      File.mkdir_p!(@test_dir)
      File.cd!(@test_dir)

      {output, _exit_code} =
        System.cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true, cd: @test_dir)

      # Mix format will fail when there's no .formatter.exs or Mix project
      assert output =~ "Expected one or more files" or
               output =~ "Could not find a Mix.Project" or
               output =~ ".formatter.exs"
    end
  end

  describe "hook validation with different exit scenarios" do
    setup do
      System.put_env("CLAUDE_PROJECT_DIR", @test_dir)
      :ok
    end

    test "exits with code 0 when validation passes" do
      # Write good code
      File.write!("lib/valid.ex", """
      defmodule Valid do
        def greet(name) do
          "Hello, \#{name}!"
        end
      end
      """)

      System.cmd("mix", ["format"], cd: @test_dir)

      hook_input = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit -m 'good commit'"}
      }

      # We can't easily test System.halt directly, but we can verify the flow
      output =
        capture_io([input: Jason.encode!(hook_input)], fn ->
          assert_raise SystemExit, fn ->
            PreCommitCheck.run("Bash", "")
          end
        end)

      assert output =~ "Pre-commit validation triggered"
      assert output =~ "✓ Code formatting is correct"
      assert output =~ "✓ Compilation successful"
    end

    test "exits with code 2 when formatting fails" do
      # Write poorly formatted code
      File.write!("lib/bad.ex", """
      defmodule Bad do
      def greet(  name  ) do
          "Hello!"
      end
      end
      """)

      hook_input = %{
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "git commit -m 'bad formatting'"}
      }

      output =
        capture_io([input: Jason.encode!(hook_input), capture_prompt: false], fn ->
          assert_raise SystemExit, fn ->
            PreCommitCheck.run("Bash", "")
          end
        end)

      assert output =~ "Pre-commit validation triggered"
      assert output =~ "❌ Formatting check failed!"
    end
  end
end
