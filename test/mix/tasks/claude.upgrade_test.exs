defmodule Mix.Tasks.Claude.UpgradeTest do
  use ExUnit.Case, async: true
  import Igniter.Test

  alias Mix.Tasks.Claude.Upgrade

  describe "upgrade from versions < v0.3.2" do
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
               String.contains?(notice, "Claude has been upgraded!")
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

    test "handles custom old hooks by using default hooks" do
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
      assert config.hooks.stop == [:compile, :format]
      assert config.hooks.subagent_stop == [:compile, :format]
      assert config.hooks.post_tool_use == [:compile, :format]
      assert config.hooks.pre_tool_use == [:compile, :format, :unused_deps]
      refute Map.has_key?(config.hooks, :custom_hooks_detected)
    end

    test "generated .claude.exs is valid Elixir syntax" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                My.Custom.Hook
              ],
              subagents: [
                %{name: "Test Agent", description: "Test", prompt: "Test"}
              ]
            }
            """
          }
        )
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.0"]})
        |> Upgrade.igniter()

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert {config, _} = Code.eval_string(content)
      assert is_map(config)
      assert is_map(config.hooks)
      assert is_list(config.subagents)
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
        |> Igniter.assign(:args, %{options: [from: "0.2.4", to: "0.3.2"]})
        |> Upgrade.igniter()

      notices = igniter.notices

      assert Enum.any?(notices, fn notice ->
               String.contains?(notice, "Claude has been upgraded!")
             end)

      assert Enum.any?(notices, fn notice ->
               String.contains?(notice, "Hook System Overhaul")
             end)
    end
  end

  describe "version handling" do
    test "runs migration for v0.3.0 and v0.3.1" do
      # Test v0.3.0
      igniter_030 =
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
        |> Igniter.assign(:args, %{options: [from: "0.3.0", to: "0.3.2"]})
        |> Upgrade.igniter()

      assert Igniter.changed?(igniter_030, ".claude.exs")
      assert Enum.any?(igniter_030.notices, &String.contains?(&1, "Claude has been upgraded!"))

      # Test v0.3.1
      igniter_031 =
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
        |> Igniter.assign(:args, %{options: [from: "0.3.1", to: "0.3.2"]})
        |> Upgrade.igniter()

      assert Igniter.changed?(igniter_031, ".claude.exs")
      assert Enum.any?(igniter_031.notices, &String.contains?(&1, "Claude has been upgraded!"))
    end

    test "does not run migration for versions >= 0.3.2" do
      igniter =
        test_project(files: %{})
        |> Igniter.assign(:args, %{options: [from: "0.3.2", to: "0.3.3"]})
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

    test "handles positional arguments as expected from mix igniter.upgrade" do
      # This tests that the upgrader works when called with positional arguments
      # as it would be from mix igniter.upgrade
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
        |> Map.put(:args, %Igniter.Mix.Task.Args{
          positional: ["0.2.4", "0.3.0"],
          options: [],
          argv_flags: [],
          argv: ["0.2.4", "0.3.0"]
        })
        |> Upgrade.igniter()

      # Should have migrated the hooks
      assert Igniter.changed?(igniter, ".claude.exs")

      # Should have added upgrade notices
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Claude has been upgraded!")
             end)
    end
  end
end
