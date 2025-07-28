defmodule Mix.Tasks.Claude.Subagents.ListTest do
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

  describe "list task" do
    test "lists configured subagents", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Test Expert",
            description: "Expert in testing",
            prompt: "You are an expert in testing...",
            tools: [:read, :grep],
            usage_rules: ["ex_unit", "mox"]
          }
        ]
      }
      """)

      output =
        in_project_env(project, fn ->
          capture_io(fn ->
            Mix.Task.run("claude.subagents.list")
          end)
        end)

      assert String.contains?(output, "Configured subagents:")
      assert String.contains?(output, "Test Expert")
      assert String.contains?(output, "Expert in testing")
      assert String.contains?(output, "Tools: Read, Grep")
      assert String.contains?(output, "Usage rules: ex_unit, mox")
    end

    test "shows message when no subagents configured", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")
      File.write!(claude_exs_path, "%{}")

      output =
        in_project_env(project, fn ->
          capture_io(fn ->
            Mix.Task.run("claude.subagents.list")
          end)
        end)

      assert String.contains?(output, "No subagents configured")
    end

    test "lists multiple subagents", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Agent One",
            description: "First agent",
            prompt: "First prompt",
            tools: [:read]
          },
          %{
            name: "Agent Two",
            description: "Second agent", 
            prompt: "Second prompt",
            usage_rules: ["phoenix"]
          }
        ]
      }
      """)

      output =
        in_project_env(project, fn ->
          capture_io(fn ->
            Mix.Task.run("claude.subagents.list")
          end)
        end)

      assert String.contains?(output, "Agent One")
      assert String.contains?(output, "First agent")
      assert String.contains?(output, "Tools: Read")

      assert String.contains?(output, "Agent Two")
      assert String.contains?(output, "Second agent")
      assert String.contains?(output, "Usage rules: phoenix")
    end

    test "handles subagents without optional fields", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")

      File.write!(claude_exs_path, """
      %{
        subagents: [
          %{
            name: "Minimal Agent",
            description: "A minimal agent",
            prompt: "Minimal prompt"
          }
        ]
      }
      """)

      output =
        in_project_env(project, fn ->
          capture_io(fn ->
            Mix.Task.run("claude.subagents.list")
          end)
        end)

      assert String.contains?(output, "Minimal Agent")
      assert String.contains?(output, "A minimal agent")
      # Should not show Tools or Usage rules lines
      refute String.contains?(output, "Tools:")
      refute String.contains?(output, "Usage rules:")
    end

    test "handles missing .claude.exs file", %{project: project} do
      output =
        in_project_env(project, fn ->
          capture_io(:stderr, fn ->
            Mix.Task.run("claude.subagents.list")
          end)
        end)

      assert String.contains?(output, "No .claude.exs file found")
    end

    test "handles invalid .claude.exs file", %{project: project} do
      claude_exs_path = Path.join(project.root, ".claude.exs")
      File.write!(claude_exs_path, "invalid elixir code {")

      output =
        in_project_env(project, fn ->
          capture_io(:stderr, fn ->
            Mix.Task.run("claude.subagents.list")
          end)
        end)

      assert String.contains?(output, "Failed to load .claude.exs")
    end
  end
end
