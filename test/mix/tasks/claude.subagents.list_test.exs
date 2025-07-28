defmodule Mix.Tasks.Claude.Subagents.ListTest do
  use ExUnit.Case, async: false
  use Mimic
  import ExUnit.CaptureIO

  alias Claude.TestHelpers

  describe "run/1" do
    setup do
      TestHelpers.setup_mix_tasks()
    end

    test "lists configured subagents" do
      TestHelpers.in_tmp(fn tmp_dir ->
        System.put_env("CLAUDE_PROJECT_DIR", tmp_dir)

        File.write!(".claude.exs", """
        %{
          subagents: [
            %{
              name: "Ecto Expert",
              description: "Expert in Ecto database operations",
              prompt: "You are an Ecto expert.",
              tools: [:read, :grep, :task],
              usage_rules: ["ecto", "ecto_sql"]
            },
            %{
              name: "Phoenix Expert",
              description: "Expert in Phoenix web framework",
              prompt: "You are a Phoenix expert.",
              tools: [:read, :edit, :write]
            }
          ]
        }
        """)

        output =
          capture_io(fn ->
            Mix.Task.run("claude.subagents.list", [])
          end)

        assert output =~ "Configured subagents:"
        assert output =~ "• Ecto Expert"
        assert output =~ "Expert in Ecto database operations"
        assert output =~ "Tools: Read, Grep, Task"
        assert output =~ "Usage rules: ecto, ecto_sql"
        assert output =~ "• Phoenix Expert"
        assert output =~ "Expert in Phoenix web framework"
        assert output =~ "Tools: Read, Edit, Write"
      end)
    end

    test "handles no subagents" do
      TestHelpers.in_tmp(fn tmp_dir ->
        System.put_env("CLAUDE_PROJECT_DIR", tmp_dir)

        File.write!(".claude.exs", "%{}")

        output =
          capture_io(fn ->
            Mix.Task.run("claude.subagents.list", [])
          end)

        assert output =~ "No subagents configured"
      end)
    end

    test "handles missing .claude.exs" do
      TestHelpers.in_tmp(fn tmp_dir ->
        System.put_env("CLAUDE_PROJECT_DIR", tmp_dir)

        output =
          capture_io(fn ->
            Mix.Task.run("claude.subagents.list", [])
          end)

        assert output =~ "No subagents configured"
      end)
    end
  end
end
