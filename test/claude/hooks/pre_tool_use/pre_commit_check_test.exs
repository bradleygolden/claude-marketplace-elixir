defmodule Claude.Hooks.PreToolUse.PreCommitCheckTest do
  use Claude.ClaudeCodeCase, setup_project?: true

  alias Claude.Hooks.PreToolUse.PreCommitCheck
  alias Claude.Test.Fixtures
  import Claude.Test.HookTestHelpers

  describe "run/1" do
    test "returns :ok for :eof input" do
      assert PreCommitCheck.run(:eof) == :ok
    end

    test "handles invalid JSON input gracefully" do
      assert_hook_success(PreCommitCheck, "invalid json")
    end

    test "ignores non-Bash tools" do
      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Write",
          tool_input: Fixtures.tool_input(:write, file_path: "/some/file.ex"),
          cwd: "."
        )

      assert_hook_success(PreCommitCheck, input)
    end

    test "ignores non-git-commit bash commands" do
      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "ls -la"),
          cwd: "."
        )

      assert_hook_success(PreCommitCheck, input)
    end

    test "handles missing command in tool_input" do
      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: %{},
          cwd: "."
        )

      assert_hook_success(PreCommitCheck, input)
    end

    test "allows commit when all checks pass", %{test_dir: test_dir} do
      # Create a properly formatted file
      create_file(test_dir, "lib/good.ex", """
      defmodule Good do
        def hello do
          :world
        end
      end
      """)

      # Ensure project files exist
      assert File.exists?(Path.join(test_dir, ".formatter.exs"))
      assert File.exists?(Path.join(test_dir, "mix.exs"))

      # Format the file
      System.cmd("mix", ["format"], cd: test_dir)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'test commit'"),
          cwd: test_dir
        )

      assert_hook_success(PreCommitCheck, input)
    end

    test "blocks commit when formatting issues exist", %{test_dir: test_dir} do
      # Create an unformatted file
      create_file(test_dir, "lib/bad_format.ex", """
      defmodule BadFormat   do
      def hello(  x,y  )   do
        x+y
      end
      end
      """)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'bad formatting'"),
          cwd: test_dir
        )

      stderr = assert_hook_error(PreCommitCheck, input)
      assert stderr =~ "Pre-commit checks failed"
      assert stderr =~ "FORMATTING ISSUES DETECTED"
      assert stderr =~ "mix format"
    end

    test "blocks commit when compilation errors exist", %{test_dir: test_dir} do
      # Create a file with compilation error
      create_file(test_dir, "lib/bad_compile.ex", """
      defmodule BadCompile do
        def hello(name) do
          "Hello, \#{undefined_var}!"
        end
      end
      """)

      # Format it first so we only get compilation errors
      System.cmd("mix", ["format"], cd: test_dir)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'compilation error'"),
          cwd: test_dir
        )

      stderr = assert_hook_error(PreCommitCheck, input)
      assert stderr =~ "Pre-commit checks failed"
      assert stderr =~ "COMPILATION ERRORS DETECTED"
      assert stderr =~ "undefined variable"
    end

    test "blocks commit when compilation warnings exist", %{test_dir: test_dir} do
      # Create a file with unused variable warning
      create_file(test_dir, "lib/warning.ex", """
      defmodule Warning do
        def hello do
          unused = 42
          :world
        end
      end
      """)

      # Format it first
      System.cmd("mix", ["format"], cd: test_dir)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'unused variable'"),
          cwd: test_dir
        )

      stderr = assert_hook_error(PreCommitCheck, input)
      assert stderr =~ "Pre-commit checks failed"
      assert stderr =~ "COMPILATION ERRORS DETECTED"
      assert stderr =~ "variable \"unused\" is unused"
    end

    test "reports multiple failures", %{test_dir: test_dir} do
      # Create a file with both formatting and compilation issues
      create_file(test_dir, "lib/multiple_issues.ex", """
      defmodule MultipleIssues   do
      def hello(name)   do
        unused  =  42
        "Hello, \#{undefined_var}!"
      end
      end
      """)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'multiple issues'"),
          cwd: test_dir
        )

      stderr = assert_hook_error(PreCommitCheck, input)
      assert stderr =~ "Pre-commit checks failed"
      # Should show both formatting and compilation issues
      assert stderr =~ "FORMATTING ISSUES DETECTED"
      assert stderr =~ "COMPILATION ERRORS DETECTED"
    end

    test "handles commit with message containing special characters", %{test_dir: test_dir} do
      # Create a file with formatting issues to ensure the commit check fails
      create_file(test_dir, "lib/bad.ex", """
      defmodule Bad   do
      def hello(  )   do
        :world
      end
      end
      """)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input:
            Fixtures.tool_input(:bash, command: "git commit -m 'fix: issue #123 & \"quoted\"'"),
          cwd: test_dir
        )

      # Will fail on formatting/compilation, but should detect it as a commit
      stderr = assert_hook_error(PreCommitCheck, input)
      assert stderr =~ "Pre-commit checks failed"
    end
  end
end
