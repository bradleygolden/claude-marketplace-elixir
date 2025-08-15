defmodule Claude.NestedMemoriesTest do
  use Claude.ClaudeCodeCase

  describe "generate/1" do
    test "does nothing when no nested_memories config exists" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      refute Enum.any?(result.tasks, fn
               {"usage_rules.sync", _args} -> true
               _ -> false
             end)
    end

    test "handles empty nested_memories config" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{}
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert result == igniter
    end

    test "handles missing .claude.exs file gracefully" do
      igniter = test_project()

      result = Claude.NestedMemories.generate(igniter)

      assert result == igniter
    end

    test "handles invalid .claude.exs syntax gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                this is invalid syntax
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert result == igniter
    end
  end

  describe "integration with claude.install" do
    test "nested memories are part of the install pipeline" do
      igniter = test_project()

      result = Igniter.compose_task(igniter, "claude.install")

      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", ["CLAUDE.md" | _]} -> true
               _ -> false
             end)
    end
  end

  describe "generate/1 with mocked File.dir?" do
    setup do
      Mimic.stub(File, :dir?, fn
        "lib/existing" -> true
        "lib/my_app" -> true
        "lib/my_app_web/live" -> true
        "test" -> true
        _ -> false
      end)

      :ok
    end

    test "generates usage_rules.sync tasks for existing directories" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => ["phoenix:ecto", "phoenix:elixir"],
                "lib/my_app_web/live" => ["phoenix:liveview"],
                "test" => ["usage_rules:elixir"]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      tasks = result.tasks

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/my_app/CLAUDE.md") and
                   Enum.member?(args, "phoenix:ecto") and
                   Enum.member?(args, "phoenix:elixir") and
                   Enum.member?(args, "--yes")

               _ ->
                 false
             end)

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/my_app_web/live/CLAUDE.md") and
                   Enum.member?(args, "phoenix:liveview") and
                   Enum.member?(args, "--yes")

               _ ->
                 false
             end)

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "test/CLAUDE.md") and
                   Enum.member?(args, "usage_rules:elixir") and
                   Enum.member?(args, "--yes")

               _ ->
                 false
             end)
    end

    test "only processes directories that exist" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/existing" => ["phoenix:ecto"],
                "lib/non_existing" => ["phoenix:html"]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      tasks = result.tasks

      assert Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/existing/CLAUDE.md")

               _ ->
                 false
             end)

      refute Enum.any?(tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "lib/non_existing/CLAUDE.md")

               _ ->
                 false
             end)
    end

    test "converts atom rule specs to strings" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => [:phoenix_ecto, :usage_rules_elixir]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert Enum.any?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 Enum.member?(args, "phoenix_ecto") and
                   Enum.member?(args, "usage_rules_elixir")

               _ ->
                 false
             end)
    end

    test "adds --yes flag to all usage_rules.sync tasks" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              nested_memories: %{
                "lib/my_app" => ["phoenix:ecto"]
              }
            }
            """
          }
        )

      result = Claude.NestedMemories.generate(igniter)

      assert Enum.all?(result.tasks, fn
               {"usage_rules.sync", args} ->
                 "--yes" in args

               _ ->
                 true
             end)
    end
  end
end
