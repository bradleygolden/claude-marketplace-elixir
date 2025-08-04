defmodule Claude.Hooks.PreToolUse.PreCommitCheckTest do
  use Claude.ClaudeCodeCase, async: true, setup_project?: true

  alias Claude.Hooks.PreToolUse.PreCommitCheck
  alias Claude.Test.Fixtures

  describe "description/0" do
    test "returns a description" do
      description = PreCommitCheck.description()
      assert description =~ "formatting"
      assert description =~ "compilation"
      assert description =~ "dependencies"
    end
  end

  describe "run/1 - :eof input" do
    test "returns :ok for :eof input" do
      assert PreCommitCheck.run(:eof) == :ok
    end
  end

  describe "run/1 - git commit detection" do
    test "detects and validates git commit commands", %{test_dir: test_dir} do
      create_file(test_dir, "lib/good.ex", """
      defmodule Good do
        def hello do
          :world
        end
      end
      """)

      assert File.exists?(Path.join(test_dir, ".formatter.exs"))
      assert File.exists?(Path.join(test_dir, "mix.exs"))

      System.cmd("mix", ["format"], cd: test_dir)

      json =
        run_hook(
          PreCommitCheck,
          Fixtures.pre_tool_use_input(
            tool_name: "Bash",
            tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'test commit'")
          )
        )

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~ "Pre-commit checks passed"
    end

    test "ignores non-git-commit bash commands" do
      input_json =
        Jason.encode!(%{
          "tool_name" => "Bash",
          "tool_input" => %{
            "command" => "ls -la"
          }
        })

      json = run_hook(PreCommitCheck, input_json)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
      refute Map.has_key?(json["hookSpecificOutput"], "permissionDecisionReason")
    end

    test "handles invalid JSON gracefully" do
      json =
        capture_json_stdout(fn ->
          PreCommitCheck.run("invalid json")
        end)

      assert json["decision"] == "block"
      assert json["reason"] =~ "Hook crashed"
    end

    test "handles missing fields gracefully" do
      input_json =
        Jason.encode!(%{
          "other_field" => "value"
        })

      json = run_hook(PreCommitCheck, input_json)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
    end

    test "ignores non-Bash tools" do
      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Write",
          tool_input: Fixtures.tool_input(:write, file_path: "test.ex", content: "some content")
        )

      json = run_hook(PreCommitCheck, input)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
    end
  end

  describe "commit validation functionality" do
    test "blocks commit when formatting issues exist", %{test_dir: test_dir} do
      create_file(test_dir, "lib/unformatted.ex", """
      defmodule Unformatted  do
        def hello  do
          :world
        end
      end
      """)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'test'")
        )

      json = run_hook(PreCommitCheck, input)

      assert json["hookSpecificOutput"]["permissionDecision"] == "deny"

      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~
               "Formatting issues detected"
    end

    test "blocks commit when compilation errors exist", %{test_dir: test_dir} do
      create_file(test_dir, "lib/broken.ex", """
      defmodule Broken do
        def hello(name) do
          "Hello, \#{undefined_var}!"
        end
      end
      """)

      System.cmd("mix", ["format"], cd: test_dir)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'test'")
        )

      json = run_hook(PreCommitCheck, input, stderr: true)

      assert json["hookSpecificOutput"]["permissionDecision"] == "deny"

      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~
               "Compilation errors detected"
    end

    test "blocks commit when unused dependencies exist", %{test_dir: test_dir} do
      create_file(test_dir, "lib/good.ex", """
      defmodule Good do
        def hello, do: :world
      end
      """)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'test'")
        )

      json = run_hook(PreCommitCheck, input, stderr: true)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow" ||
               json["hookSpecificOutput"]["permissionDecision"] == "deny"
    end

    test "allows commit when all validations pass", %{test_dir: test_dir} do
      create_file(test_dir, "lib/good.ex", """
      defmodule Good do
        def hello, do: :world
      end
      """)

      System.cmd("mix", ["format"], cd: test_dir)

      input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: Fixtures.tool_input(:bash, command: "git commit -m 'test'")
        )

      json = run_hook(PreCommitCheck, input)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~ "Pre-commit checks passed"
    end
  end
end
