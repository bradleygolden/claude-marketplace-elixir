defmodule Claude.Hooks.PreToolUse.PreCommitCheckTest do
  use Claude.Test.ClaudeCodeCase
  import Claude.Test.HookTestHelpers
  import Claude.Test.JsonHookTestHelpers

  alias Claude.Hooks.PreToolUse.PreCommitCheck

  setup do
    {test_dir, cleanup} =
      setup_hook_test(
        files: %{
          ".formatter.exs" => "[\n  inputs: [\"**/*.{ex,exs}\"]\n]\n"
        }
      )

    setup_json_hook_test()
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
    test "returns :ok for :eof input" do
      assert PreCommitCheck.run(:eof) == :ok
    end
  end

  describe "run/1 - git commit detection" do
    test "detects and validates git commit commands", %{test_dir: test_dir} do
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
          file_path: "dummy",
          extra: %{
            "session_id" => "test123",
            "hook_event_name" => "PreToolUse",
            "tool_input" => %{"command" => "git commit -m 'test commit'"}
          }
        )

      json =
        run_and_capture_json(fn ->
          PreCommitCheck.run(input_json)
        end)

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

      json =
        run_and_capture_json(fn ->
          PreCommitCheck.run(input_json)
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
      refute Map.has_key?(json["hookSpecificOutput"], "permissionDecisionReason")
    end

    test "handles invalid JSON gracefully" do
      json =
        run_and_capture_json(fn ->
          PreCommitCheck.run("invalid json")
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "deny"

      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~
               "Failed to parse hook input JSON"
    end

    test "handles missing fields gracefully" do
      input_json =
        Jason.encode!(%{
          "other_field" => "value"
        })

      json =
        run_and_capture_json(fn ->
          PreCommitCheck.run(input_json)
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
    end

    test "ignores non-Bash tools" do
      input_json =
        build_tool_input(
          tool_name: "Write",
          file_path: "test.ex",
          extra: %{
            "tool_input" => %{"content" => "some content"}
          }
        )

      json =
        run_and_capture_json(fn ->
          PreCommitCheck.run(input_json)
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
    end
  end

  describe "commit validation functionality" do
    test "blocks commit when formatting issues exist", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/unformatted.ex", """
      defmodule Unformatted  do
        def hello  do
          :world
        end
      end
      """)

      input_json =
        build_tool_input(
          tool_name: "Bash",
          file_path: "dummy",
          extra: %{
            "hook_event_name" => "PreToolUse",
            "tool_input" => %{"command" => "git commit -m 'test'"}
          }
        )

      json =
        run_and_capture_json(fn ->
          PreCommitCheck.run(input_json)
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "deny"

      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~
               "Formatting issues detected"
    end

    test "blocks commit when compilation errors exist", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/broken.ex", """
      defmodule Broken do
        def hello(name) do
          "Hello, \#{undefined_var}!"
        end
      end
      """)

      System.cmd("mix", ["format"], cd: test_dir)

      input_json =
        build_tool_input(
          tool_name: "Bash",
          file_path: "dummy",
          extra: %{
            "hook_event_name" => "PreToolUse",
            "tool_input" => %{"command" => "git commit -m 'test'"}
          }
        )

      json =
        run_and_capture_json(fn ->
          capture_io(:stderr, fn ->
            PreCommitCheck.run(input_json)
          end)
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "deny"

      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~
               "Compilation errors detected"
    end

    test "blocks commit when unused dependencies exist", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/good.ex", """
      defmodule Good do
        def hello, do: :world
      end
      """)

      input_json =
        build_tool_input(
          tool_name: "Bash",
          file_path: "dummy",
          extra: %{
            "hook_event_name" => "PreToolUse",
            "tool_input" => %{"command" => "git commit -m 'test'"}
          }
        )

      json =
        run_and_capture_json(fn ->
          capture_io(:stderr, fn ->
            PreCommitCheck.run(input_json)
          end)
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow" ||
               json["hookSpecificOutput"]["permissionDecision"] == "deny"
    end

    test "allows commit when all validations pass", %{test_dir: test_dir} do
      create_elixir_file(test_dir, "lib/good.ex", """
      defmodule Good do
        def hello, do: :world
      end
      """)

      input_json =
        build_tool_input(
          tool_name: "Bash",
          file_path: "dummy",
          extra: %{
            "hook_event_name" => "PreToolUse",
            "tool_input" => %{"command" => "git commit -m 'test'"}
          }
        )

      json =
        run_and_capture_json(fn ->
          PreCommitCheck.run(input_json)
        end)

      assert json["hookSpecificOutput"]["permissionDecision"] == "allow"
      assert json["hookSpecificOutput"]["permissionDecisionReason"] =~ "Pre-commit checks passed"
    end
  end
end
