defmodule Mix.Tasks.Claude.UpgradeTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Claude.Upgrade

  describe "upgrade from v0.2.4 to v0.3.0" do
    test "migrates old class-based hooks to new atom format" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter,
                Claude.Hooks.PostToolUse.CompilationChecker,
                Claude.Hooks.PreToolUse.PreCommitCheck,
                Claude.Hooks.PostToolUse.RelatedFiles
              ],
              subagents: [
                %{
                  name: "Custom Agent",
                  description: "My custom agent",
                  prompt: "Custom prompt"
                }
              ]
            }
            """
          }
        )
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.0"]})
        |> Upgrade.igniter()

      # Check that .claude.exs was updated
      assert Igniter.changed?(igniter, ".claude.exs")

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)
      {config, _} = Code.eval_string(content)

      assert is_map(config.hooks)
      assert config.hooks.stop == [:compile, :format]
      assert config.hooks.subagent_stop == [:compile, :format]
      assert config.hooks.post_tool_use == [:compile, :format]
      assert config.hooks.pre_tool_use == [:compile, :format, :unused_deps]

      assert [%{name: "Custom Agent"}] = config.subagents
    end

    test "handles projects with no hooks gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: []
            }
            """
          }
        )
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.0"]})
        |> Upgrade.igniter()

      # File shouldn't change when there are no hooks to migrate
      refute Igniter.changed?(igniter, ".claude.exs")

      # Should still complete successfully with upgrade notices
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Claude has been upgraded to v0.3.0")
             end)
    end

    test "preserves existing new format hooks" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile, :format],
                post_tool_use: [:compile],
                custom_event: ["my_custom_hook"]
              }
            }
            """
          }
        )
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.0"]})
        |> Upgrade.igniter()

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)
      {config, _} = Code.eval_string(content)

      assert config.hooks.stop == [:compile, :format]
      assert config.hooks.post_tool_use == [:compile]
      assert config.hooks.custom_event == ["my_custom_hook"]
    end

    test "handles custom old hooks with migration notice" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                My.Custom.Hook,
                Another.Custom.Hook
              ]
            }
            """
          }
        )
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.0"]})
        |> Upgrade.igniter()

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)
      {config, _} = Code.eval_string(content)

      assert is_map(config.hooks)
      assert Map.has_key?(config.hooks, :custom_hooks_detected)
      assert config.hooks.custom_hooks_detected == true
    end

    test "composes claude.install task" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter
              ]
            }
            """
          }
        )
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.0"]})
        |> Upgrade.igniter()

      assert_creates(igniter, ".claude/settings.json")
    end

    test "adds upgrade notices" do
      igniter =
        test_project(files: %{})
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.0"]})
        |> Upgrade.igniter()

      notices = igniter.notices

      assert Enum.any?(notices, fn notice ->
               String.contains?(notice, "Claude has been upgraded to v0.3.0!")
             end)

      assert Enum.any?(notices, fn notice ->
               String.contains?(notice, "Hook System Overhaul")
             end)
    end
  end

  describe "version handling" do
    test "only runs migration for versions less than 0.3.0" do
      igniter =
        test_project(files: %{})
        |> Igniter.assign(:args, %{options: [from: "0.3.0", to: "0.3.0"]})
        |> Upgrade.igniter()

      assert igniter.notices == []
    end

    test "handles missing version gracefully" do
      igniter =
        test_project(files: %{})
        |> Igniter.assign(:args, %{options: [from: nil, to: "0.3.0"]})
        |> Upgrade.igniter()

      assert igniter.notices == []
    end
  end
end
