defmodule Mix.Tasks.Claude.Subagents.GenerateTest do
  use ExUnit.Case, async: false
  use Mimic
  import ExUnit.CaptureIO

  alias Claude.TestHelpers

  describe "run/1" do
    setup do
      TestHelpers.setup_mix_tasks()
    end

    test "generates subagent markdown files from .claude.exs" do
      TestHelpers.in_tmp(fn tmp_dir ->
        # Set CLAUDE_PROJECT_DIR for the tests
        System.put_env("CLAUDE_PROJECT_DIR", tmp_dir)

        # Create .claude.exs with a test subagent
        File.write!(".claude.exs", """
        %{
          subagents: [
            %{
              name: "Test Expert",
              description: "An expert in testing",
              prompt: "You are a test expert.",
              tools: [:read, :grep],
              plugins: [{Claude.Subagents.Plugins.UsageRules, %{deps: ["ex_unit"]}}]
            }
          ]
        }
        """)

        # Create a mock usage rules file
        File.mkdir_p!("deps/ex_unit")

        File.write!("deps/ex_unit/usage-rules.md", """
        # ExUnit Usage Rules

        Always use descriptive test names.
        """)

        # Run the task
        output =
          capture_io(fn ->
            Mix.Task.run("claude.subagents.generate", [])
          end)

        # Check output
        assert output =~ "Generated 1 subagent(s)"
        assert output =~ "Test Expert"

        # Check that the file was created
        assert File.exists?(".claude/agents/test-expert.md")

        content = File.read!(".claude/agents/test-expert.md")
        assert content =~ "# Test Expert"
        assert content =~ "An expert in testing"
        assert content =~ "You are a test expert."
        assert content =~ "- Read"
        assert content =~ "- Grep"
      end)
    end

    test "handles missing .claude.exs gracefully" do
      TestHelpers.in_tmp(fn tmp_dir ->
        System.put_env("CLAUDE_PROJECT_DIR", tmp_dir)

        # Run without .claude.exs
        output =
          capture_io(:stderr, fn ->
            Mix.Task.run("claude.subagents.generate", [])
          end)

        # Should show error
        assert output =~ "No .claude.exs file found"
      end)
    end

    test "handles empty subagents list" do
      TestHelpers.in_tmp(fn tmp_dir ->
        System.put_env("CLAUDE_PROJECT_DIR", tmp_dir)

        File.write!(".claude.exs", "%{subagents: []}")

        # Should complete without creating any files
        capture_io(fn ->
          Mix.Task.run("claude.subagents.generate", [])
        end)

        refute File.exists?(".claude/agents")
      end)
    end

    test "handles subagent generation errors gracefully" do
      TestHelpers.in_tmp(fn tmp_dir ->
        System.put_env("CLAUDE_PROJECT_DIR", tmp_dir)

        # Create invalid subagent config (missing required fields)
        File.write!(".claude.exs", """
        %{
          subagents: [
            %{description: "Missing name field"}
          ]
        }
        """)

        output =
          capture_io(:stderr, fn ->
            Mix.Task.run("claude.subagents.generate", [])
          end)

        # Should show error about missing name
        assert output =~ "Failed to generate subagents"
      end)
    end
  end
end
