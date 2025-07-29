defmodule Claude.Hooks.PreToolUse.PreCommitCheckTest do
  use Claude.Test.ClaudeCodeCase
  import Claude.Test.HookTestHelpers

  alias Claude.Hooks.PreToolUse.PreCommitCheck

  setup do
    {test_dir, cleanup} =
      setup_hook_test(
        files: %{
          ".formatter.exs" => "[\n  inputs: [\"**/*.{ex,exs}\"]\n]\n"
        }
      )

    on_exit(cleanup)
    {:ok, test_dir: test_dir}
  end

  describe "config/0" do
    test "returns proper hook configuration" do
      config = PreCommitCheck.config()

      assert config.type == "command"
      assert config.command =~ "Hook command configured by installer"
    end
  end

  describe "description/0" do
    test "returns a description" do
      description = PreCommitCheck.description()
      assert description =~ "formatting"
      assert description =~ "compilation"
      assert description =~ "dependencies"
    end
  end

  describe "run/1 - :eof input" do
    test "handles :eof input by exiting with code 0" do
      expect(System, :halt, fn 0 -> :ok end)

      PreCommitCheck.run(:eof)
    end
  end

  describe "run/1 - git commit detection" do
    test "detects and validates git commit commands", %{test_dir: test_dir} do
      # CLAUDE_PROJECT_DIR is already set by setup_hook_test
      create_elixir_file(test_dir, "lib/good.ex", """
      defmodule Good do
        def hello do
          :world
        end
      end
      """)

      System.cmd("mix", ["format"], cd: test_dir)

      input_json =
        build_tool_input(
          tool_name: "Bash",
          # Required by helper but not used for Bash
          file_path: "dummy",
          extra: %{
            "session_id" => "test123",
            "hook_event_name" => "PreToolUse",
            "tool_input" => %{"command" => "git commit -m 'test commit'"}
          }
        )

      stub(System, :halt, fn 0 -> :ok end)

      assert capture_io([input: input_json], fn ->
               PreCommitCheck.run(input_json)
             end) =~ "Pre-commit validation triggered"
    end

    test "ignores non-git-commit bash commands" do
      input_json =
        Jason.encode!(%{
          "tool_name" => "Bash",
          "tool_input" => %{
            "command" => "ls -la"
          }
        })

      stub(System, :halt, fn 0 -> :ok end)

      assert capture_io([input: input_json], fn ->
               PreCommitCheck.run(input_json)
             end) == ""
    end

    test "handles invalid JSON gracefully" do
      stub(System, :halt, fn 1 -> :ok end)

      assert capture_io(:stderr, fn ->
               PreCommitCheck.run("invalid json")
             end) =~ "Failed to parse hook input JSON"
    end

    test "handles missing fields gracefully" do
      input_json =
        Jason.encode!(%{
          "other_field" => "value"
        })

      stub(System, :halt, fn 0 -> :ok end)

      assert capture_io([input: input_json], fn ->
               PreCommitCheck.run(input_json)
             end) == ""
    end
  end

  describe "validation logic" do
    test "passes when code is properly formatted and compiles", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/good_code.ex", """
      defmodule GoodCode do
        def hello(name) do
          "Hello, \#{name}!"
        end
      end
      """)

      System.cmd("mix", ["format"], cd: test_dir)

      output =
        capture_io(fn ->
          {output, exit_code} =
            System.cmd("mix", ["format", "--check-formatted"],
              stderr_to_stdout: true,
              cd: test_dir
            )

          assert exit_code == 0
          IO.puts(output)

          {output, exit_code} =
            System.cmd("mix", ["compile", "--warnings-as-errors"],
              stderr_to_stdout: true,
              cd: test_dir
            )

          assert exit_code == 0
          IO.puts(output)
        end)

      refute output =~ "Formatting check failed"
      refute output =~ "Compilation check failed"
    end

    test "fails when code has formatting issues", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/bad_format.ex", """
      defmodule BadFormat do
      def hello(  name  ) do
        "Hello, \#{ name }!"
      end
      end
      """)

      {output, exit_code} =
        System.cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true, cd: test_dir)

      assert exit_code != 0
      assert output =~ "bad_format.ex" or output =~ "not formatted"
    end

    test "fails when code has compilation errors", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/bad_compile.ex", """
      defmodule BadCompile do
        def hello(name) do
          undefined_function()
        end
      end
      """)

      {output, exit_code} =
        System.cmd("mix", ["compile", "--warnings-as-errors"],
          stderr_to_stdout: true,
          cd: test_dir
        )

      assert exit_code != 0
      assert output =~ "undefined_function"
    end

    test "fails when code has warnings with --warnings-as-errors", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/warning_code.ex", """
      defmodule WarningCode do
        def hello(name, unused) do
          "Hello, \#{name}!"
        end
      end
      """)

      {output, exit_code} =
        System.cmd("mix", ["compile", "--warnings-as-errors"],
          stderr_to_stdout: true,
          cd: test_dir
        )

      assert exit_code != 0
      assert output =~ "unused"
    end

    test "passes when no unused dependencies exist", %{test_dir: test_dir} do
      File.write!(Path.join(test_dir, "mix.lock"), """
      %{}
      """)

      {output, exit_code} =
        System.cmd("mix", ["deps.unlock", "--check-unused"],
          stderr_to_stdout: true,
          cd: test_dir
        )

      assert exit_code == 0
      refute output =~ "Unused dependencies"
    end

    test "fails when unused dependencies are detected", %{test_dir: test_dir} do
      File.write!(Path.join(test_dir, "mix.lock"), """
      %{
        "unused_dep": {:hex, :unused_dep, "1.0.0", "abc123", [:mix], [], "hexpm", "def456"}
      }
      """)

      {output, exit_code} =
        System.cmd("mix", ["deps.unlock", "--check-unused"],
          stderr_to_stdout: true,
          cd: test_dir
        )

      assert exit_code != 0
      assert output =~ "unused_dep"
    end
  end

  describe "edge cases" do
    test "handles missing mix.exs gracefully", %{test_dir: test_dir} do
      File.rm!(Path.join(test_dir, "mix.exs"))

      {output, _exit_code} = System.cmd("mix", ["compile"], stderr_to_stdout: true, cd: test_dir)

      assert output =~ "Could not find a Mix.Project"
    end

    test "handles empty project directory", %{test_dir: test_dir} do
      File.rm_rf!(test_dir)
      File.mkdir_p!(test_dir)
      File.cd!(test_dir)

      {output, _exit_code} =
        System.cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true, cd: test_dir)

      assert output =~ "Expected one or more files" or
               output =~ "Could not find a Mix.Project" or
               output =~ ".formatter.exs"
    end
  end

  describe "hook validation with different exit scenarios" do
    test "exits with code 0 when validation passes", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/valid.ex", """
      defmodule Valid do
        def greet(name) do
          "Hello, \#{name}!"
        end
      end
      """)

      System.cmd("mix", ["format"], cd: test_dir)

      File.write!(Path.join(test_dir, "mix.lock"), "%{}")

      input_json =
        Jason.encode!(%{
          "tool_name" => "Bash",
          "tool_input" => %{"command" => "git commit -m 'good commit'"}
        })

      stub(System, :halt, fn 0 -> :ok end)

      output =
        capture_io([input: input_json], fn ->
          PreCommitCheck.run(input_json)
        end)

      assert output =~ "Pre-commit validation triggered"
      assert output =~ "✓ Code formatting is correct"
      assert output =~ "✓ Compilation successful"
      assert output =~ "✓ No unused dependencies found"
    end

    test "exits with code 2 when formatting fails", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/bad.ex", """
      defmodule Bad do
      def greet(  name  ) do
          "Hello!"
      end
      end
      """)

      input_json =
        Jason.encode!(%{
          "tool_name" => "Bash",
          "tool_input" => %{"command" => "git commit -m 'bad formatting'"}
        })

      stub(System, :halt, fn 2 -> :ok end)

      stdout =
        capture_io(fn ->
          stderr =
            capture_stderr(fn ->
              PreCommitCheck.run(input_json)
            end)

          assert stderr =~ "❌ Formatting check failed!"
        end)

      assert stdout =~ "Pre-commit validation triggered"
    end
  end
end
