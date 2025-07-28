defmodule Mix.Tasks.Claude.Subagents.GenerateTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  alias Claude.Test.ProjectBuilder
  alias Claude.TestHelpers

  setup do
    TestHelpers.setup_mix_tasks()
    project = ProjectBuilder.build_elixir_project()
    on_exit(fn -> ProjectBuilder.cleanup(project) end)
    {:ok, project: project}
  end

  defp in_project_env(%{root: root}, fun) do
    original_env = System.get_env("CLAUDE_PROJECT_DIR")
    System.put_env("CLAUDE_PROJECT_DIR", root)

    try do
      fun.()
    after
      if original_env do
        System.put_env("CLAUDE_PROJECT_DIR", original_env)
      else
        System.delete_env("CLAUDE_PROJECT_DIR")
      end
    end
  end

  describe "generate task" do
    test "generates subagent markdown files", %{project: project} do
      # Create .claude.exs with subagent config
      claude_exs_path = Path.join(project.root, ".claude.exs")

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Test Expert",
            description: "Expert in testing",
            prompt: "You are an expert in testing...",
            tools: [:read, :grep],
            usage_rules: ["ex_unit"]
          }
        ]
      }
      """)

      # Run the generate task
      in_project_env(project, fn ->
        Mix.Task.run("claude.subagents.generate")
      end)

      # Check that the markdown file was created
      agent_file = Path.join([project.root, ".claude", "agents", "test-expert.md"])
      assert File.exists?(agent_file)

      # Verify content
      content = File.read!(agent_file)
      assert String.contains?(content, "# Test Expert")
      assert String.contains?(content, "Expert in testing")
      assert String.contains?(content, "You are an expert in testing")
      assert String.contains?(content, "- Read")
      assert String.contains?(content, "- Grep")
    end

    test "handles empty subagents list", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")
      File.write!(claude_exs_path, "%{subagents: []}")

      # Should not error
      in_project_env(project, fn ->
        Mix.Task.run("claude.subagents.generate")
      end)
    end

    test "generates multiple subagents", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Agent One",
            description: "First agent",
            prompt: "First prompt"
          },
          %{
            name: "Agent Two",
            description: "Second agent", 
            prompt: "Second prompt"
          }
        ]
      }
      """)

      in_project_env(project, fn ->
        Mix.Task.run("claude.subagents.generate")
      end)

      # Check both files exist
      assert File.exists?(Path.join([project.root, ".claude", "agents", "agent-one.md"]))
      assert File.exists?(Path.join([project.root, ".claude", "agents", "agent-two.md"]))
    end

    test "applies usage rules plugin", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")

      # Create mock usage rules files
      deps_dir = Path.join(project.root, "deps")
      ex_unit_dir = Path.join(deps_dir, "ex_unit")
      File.mkdir_p!(ex_unit_dir)

      File.write!(Path.join(ex_unit_dir, "usage-rules.md"), """
      # ExUnit Usage Rules

      ## Testing Best Practices
      - Always use descriptive test names
      - Group related tests with describe blocks
      """)

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Test Agent",
            description: "Testing expert",
            prompt: "You are a test expert",
            usage_rules: ["ex_unit"]
          }
        ]
      }
      """)

      in_project_env(project, fn ->
        Mix.Task.run("claude.subagents.generate")
      end)

      agent_file = Path.join([project.root, ".claude", "agents", "test-agent.md"])
      content = File.read!(agent_file)

      # Should include usage rules
      assert String.contains?(content, "ExUnit Usage Rules")
      assert String.contains?(content, "Testing Best Practices")
    end

    test "sanitizes agent filenames", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Agent with Spaces & Special!@# Chars",
            description: "Test",
            prompt: "Test"
          }
        ]
      }
      """)

      in_project_env(project, fn ->
        Mix.Task.run("claude.subagents.generate")
      end)

      # Should create sanitized filename
      agent_file =
        Path.join([project.root, ".claude", "agents", "agent-with-spaces-special-chars.md"])

      assert File.exists?(agent_file)
    end

    test "handles missing .claude.exs gracefully", %{project: project} do
      # No .claude.exs file created

      # Should not crash
      output =
        in_project_env(project, fn ->
          capture_io(:stderr, fn ->
            Mix.Task.run("claude.subagents.generate")
          end)
        end)

      # Should show error message
      assert String.contains?(output, "No .claude.exs file found")
    end

    test "handles invalid subagent config", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Invalid Agent"
            # Missing required fields
          }
        ]
      }
      """)

      output =
        in_project_env(project, fn ->
          capture_io(:stderr, fn ->
            Mix.Task.run("claude.subagents.generate")
          end)
        end)

      # Should show error about missing fields
      assert String.contains?(output, "Failed to generate subagents")
    end
  end
end
