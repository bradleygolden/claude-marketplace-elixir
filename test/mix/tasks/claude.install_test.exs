defmodule Mix.Tasks.Claude.InstallTest do
  use Claude.ClaudeCodeCase, trap_halts: false

  import Igniter.Test,
    except: [test_project: 0, test_project: 1, phx_test_project: 0, phx_test_project: 1]

  describe "claude.install" do
    test "creates .claude.exs file in a new project" do
      test_project()
      |> Igniter.compose_task("claude.install")
      |> assert_creates(".claude.exs")
    end

    test "adds .claude.exs to formatter inputs automatically" do
      igniter =
        test_project(
          files: %{
            ".formatter.exs" => """
            [
              inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
            ]
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".formatter.exs")

      source = Rewrite.source!(igniter.rewrite, ".formatter.exs")
      content = Rewrite.Source.get(source, :content)
      {formatter_config, _} = Code.eval_string(content)

      assert ".claude.exs" in formatter_config[:inputs]
    end

    test "handles missing .formatter.exs file" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".formatter.exs")

      formatter_source = Rewrite.source!(igniter.rewrite, ".formatter.exs")
      content = Rewrite.Source.get(formatter_source, :content)
      assert String.contains?(content, ".claude.exs")
    end

    test "formatter update is idempotent when .claude.exs already present" do
      igniter =
        test_project(
          files: %{
            ".formatter.exs" => """
            [
              inputs: [".claude.exs", "{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
            ]
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_unchanged(igniter, ".formatter.exs")
    end

    test "creates CLAUDE.md through usage_rules.sync task" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.tasks, fn {task_name, _args} ->
               task_name == "usage_rules.sync"
             end)
    end

    test "inlines base usage rules by default" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      {"usage_rules.sync", args} =
        Enum.find(igniter.tasks, fn {task, _} -> task == "usage_rules.sync" end)

      inline_arg =
        args
        |> Enum.drop_while(&(&1 != "--inline"))
        |> Enum.at(1, "")

      assert String.contains?(inline_arg, "usage_rules:all")
    end

    test "creates claude settings if one doesn't exist" do
      test_project()
      |> Igniter.compose_task("claude.install")
      |> assert_creates(".claude/settings.json")
    end

    test "adds Base plugin to existing .claude.exs file" do
      custom_config = """
      %{
        hooks: %{
          post_tool_use: [:compile, :format, "custom --task"]
        },
        custom_setting: true
      }
      """

      igniter =
        test_project(
          files: %{
            ".claude.exs" => custom_config
          }
        )
        |> Igniter.compose_task("claude.install")

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "plugins: [Claude.Plugins.Base]"
      assert content =~ "post_tool_use: [:compile, :format, \"custom --task\"]"
      assert content =~ "custom_setting: true"
    end

    test "generates .claude.exs with Base plugin" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude.exs")

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "plugins: [Claude.Plugins.Base]"
    end

    test "errors on old list-based hook format" do
      old_format_config = """
      %{
        hooks: [MyApp.CustomHook, AnotherHook]
      }
      """

      igniter =
        test_project(
          files: %{
            ".claude.exs" => old_format_config
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.issues, fn issue ->
               String.contains?(issue, "outdated hooks format") and
                 String.contains?(issue, "manually update your .claude.exs file")
             end)
    end

    test "accepts new map-based hook format and adds Base plugin" do
      new_format_config = """
      %{
        hooks: %{
          stop: [:compile, :format],
          post_tool_use: [:compile]
        }
      }
      """

      igniter =
        test_project(
          files: %{
            ".claude.exs" => new_format_config
          }
        )
        |> Igniter.compose_task("claude.install")

      assert igniter.issues == []
      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "plugins: [Claude.Plugins.Base]"
      assert content =~ "stop: [:compile, :format]"
      assert content =~ "post_tool_use: [:compile]"
    end

    test "handles mixed atom and explicit hook configurations" do
      mixed_config = """
      %{
        hooks: %{
          stop: [:compile, {"custom --task", halt_pipeline?: false}],
          post_tool_use: [:format]
        }
      }
      """

      igniter =
        test_project(
          files: %{
            ".claude.exs" => mixed_config
          }
        )
        |> Igniter.compose_task("claude.install")

      assert igniter.issues == []
      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "plugins: [Claude.Plugins.Base]"
      assert content =~ ~r/stop:.*:compile.*"custom --task".*halt_pipeline\?/s
      assert content =~ "post_tool_use: [:format]"
    end

    test "adds usage_rules dependency" do
      test_project()
      |> Igniter.compose_task("claude.install")
      |> assert_has_patch("mix.exs", """
        23 23   |    [
           24 + |      {:usage_rules, "~> 0.1", only: [:dev]}
        24 25   |      # {:dep_from_hexpm, "~> 0.3.0"},
      """)
      |> apply_igniter!()
    end

    test "detects Phoenix project and notifies about tidewave" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave MCP server has been configured")
             end)
    end

    test "does not add tidewave to non-Phoenix projects" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      refute Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave")
             end)
    end

    test "composes all required tasks" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")
      assert_creates(igniter, ".claude.exs")

      assert Enum.any?(igniter.tasks, fn {task_name, _args} ->
               task_name == "usage_rules.sync"
             end)
    end

    test "handles existing usage_rules dependency gracefully" do
      igniter =
        test_project(
          files: %{
            "mix.exs" => """
            defmodule MyApp.MixProject do
              use Mix.Project

              def project do
                [
                  app: :my_app,
                  version: "0.1.0",
                  elixir: "~> 1.14",
                  deps: deps()
                ]
              end

              defp deps do
                [
                  {:usage_rules, "~> 0.1", only: [:dev]}
                ]
              end
            end
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Igniter.changed?(igniter, "mix.exs")
    end

    test "composes usage_rules.sync task" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.tasks, fn {task_name, _args} ->
               task_name == "usage_rules.sync"
             end)
    end

    test "preserves existing mcp_servers configuration" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              mcp_servers: [:tidewave, :custom_server]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "tidewave_enabled?: false")
      assert String.contains?(content, "mcp_servers:")
      assert String.contains?(content, ":tidewave")
      assert String.contains?(content, ":custom_server")
    end

    test "installation is idempotent" do
      igniter1 =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter1, ".claude.exs")
      assert_creates(igniter1, ".claude/settings.json")

      claude_exs_source = Rewrite.source!(igniter1.rewrite, ".claude.exs")
      claude_exs_content = Rewrite.Source.get(claude_exs_source, :content)

      settings_source = Rewrite.source!(igniter1.rewrite, ".claude/settings.json")
      settings_content = Rewrite.Source.get(settings_source, :content)

      mix_exs_source = Rewrite.source!(igniter1.rewrite, "mix.exs")
      mix_exs_content = Rewrite.Source.get(mix_exs_source, :content)

      igniter2 =
        test_project(
          files: %{
            ".claude.exs" => claude_exs_content,
            ".claude/settings.json" => settings_content,
            "mix.exs" => mix_exs_content
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_unchanged(igniter2, ".claude.exs")
      assert Igniter.exists?(igniter2, ".claude/settings.json")
    end
  end

  describe "tidewave MCP configuration" do
    test "automatically installs tidewave for Phoenix projects" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave MCP server has been configured")
             end)
    end

    test "automatically adds Phoenix plugin for Phoenix projects" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".claude.exs")

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "Claude.Plugins.Phoenix")
      refute String.contains?(content, "mcp_servers:")
    end

    test "creates .mcp.json automatically for Phoenix projects" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)
      {:ok, json} = Jason.decode(content)

      assert json["mcpServers"]["tidewave"]["type"] == "http"

      assert json["mcpServers"]["tidewave"]["url"] ==
               "http://localhost:${PORT:-4000}/tidewave/mcp"
    end

    test "does not install tidewave for non-Phoenix projects" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      refute Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Phoenix project detected!")
             end)
    end

    test "skips tidewave if already configured in .claude.exs" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              mcp_servers: [:tidewave]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".claude.exs")

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)
      {:ok, json} = Jason.decode(content)

      assert map_size(json["mcpServers"]) >= 1
      assert json["mcpServers"]["tidewave"] != nil
    end

    test "does not show tidewave notice for default configuration" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              mcp_servers: [:tidewave]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave MCP server has been configured")
             end)
    end

    test "shows custom port tidewave notice when configured" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              mcp_servers: [{:tidewave, [port: 5000]}]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave MCP server has been configured") &&
                 String.contains?(notice, "http://localhost:5000/tidewave/mcp")
             end)
    end

    test "creates .mcp.json file with tidewave configuration" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              mcp_servers: [:tidewave]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)
      {:ok, json} = Jason.decode(content)

      assert json["mcpServers"]["tidewave"]["type"] == "http"
      assert json["mcpServers"]["tidewave"]["url"] == "http://localhost:4000/tidewave/mcp"
    end

    test "creates .mcp.json with custom port configuration" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              mcp_servers: [{:tidewave, [port: 5000]}]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)
      {:ok, json} = Jason.decode(content)

      assert json["mcpServers"]["tidewave"]["type"] == "http"
      assert json["mcpServers"]["tidewave"]["url"] == "http://localhost:5000/tidewave/mcp"
    end

    test "does not create .mcp.json when tidewave is disabled" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [{Claude.Plugins.Phoenix, tidewave_enabled?: false}]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Igniter.exists?(igniter, ".mcp.json")
    end
  end

  describe "edge cases" do
    test "handles missing .claude.exs" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude.exs")
      assert_creates(igniter, ".claude/settings.json")
    end

    test "updates existing settings.json with hooks" do
      igniter =
        test_project(
          files: %{
            ".claude/settings.json" => """
            {
              "customSetting": "value",
              "otherConfig": {
                "nested": true
              }
            }
            """,
            ".claude.exs" => """
            %{
              hooks: %{
                post_tool_use: [
                  {"format {{tool_input.file_path}}", when: [:write, :edit]}
                ]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude/settings.json")
    end

    test "handles corrupted settings.json" do
      igniter =
        test_project(
          files: %{
            ".claude/settings.json" => "{ invalid json"
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      assert {:ok, settings} = File.read!(".claude/settings.json") |> Jason.decode()
      assert Map.has_key?(settings, "hooks")
    end
  end

  describe "hook deduplication" do
  end

  describe "dependency handling" do
    test "adds usage_rules dependency with correct options" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert_has_patch(igniter, "mix.exs", """
        23 23   |    [
           24 + |      {:usage_rules, "~> 0.1", only: [:dev]}
        24 25   |      # {:dep_from_hexpm, "~> 0.3.0"},
      """)
    end

    test "skips usage_rules if already present with different version" do
      igniter =
        test_project(
          files: %{
            "mix.exs" => """
            defmodule MyApp.MixProject do
              use Mix.Project

              def project do
                [
                  app: :my_app,
                  version: "0.1.0",
                  elixir: "~> 1.14",
                  deps: deps()
                ]
              end

              defp deps do
                [
                  {:usage_rules, "~> 0.2", only: [:dev, :test]}
                ]
              end
            end
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Igniter.changed?(igniter, "mix.exs")
    end
  end

  describe "notice generation" do
    test "includes all relevant notices" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      notices = igniter.notices

      assert Enum.any?(notices, &String.contains?(&1, "Claude hooks have been configured"))
      assert Enum.any?(notices, &String.contains?(&1, "Syncing usage rules to CLAUDE.md"))
    end
  end

  describe "session_start hook support" do
    test "generates SessionStart hooks in settings.json when configured" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                session_start: ["custom_startup"],
                stop: [:compile, :format]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)
      assert Map.has_key?(settings["hooks"], "SessionStart")

      [%{"hooks" => session_hooks, "matcher" => "*"}] = settings["hooks"]["SessionStart"]

      assert Enum.any?(session_hooks, fn hook ->
               hook["command"] ==
                 "cd $CLAUDE_PROJECT_DIR && elixir .claude/hooks/wrapper.exs session_start"
             end)
    end

    test "does not include SessionStart by default" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile, :format],

                post_tool_use: [:compile, :format],
                pre_tool_use: [:compile, :format, :unused_deps]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      settings_source = Rewrite.source!(igniter.rewrite, ".claude/settings.json")
      settings_content = Rewrite.Source.get(settings_source, :content)
      settings = Jason.decode!(settings_content)

      refute Map.has_key?(settings["hooks"], "SessionStart")
    end

    test "handles multiple session_start hooks" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                session_start: ["custom_startup", "another_task"]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)
      assert Map.has_key?(settings["hooks"], "SessionStart")
      [%{"hooks" => session_hooks}] = settings["hooks"]["SessionStart"]

      assert length(session_hooks) == 1
      assert hd(session_hooks)["command"] =~ ".claude/hooks/wrapper.exs session_start"
    end
  end

  describe "hook configuration from .claude.exs" do
    test "handles missing hooks key in .claude.exs and adds Base plugin with hooks" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              some_other_config: true
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "plugins: [Claude.Plugins.Base]"
      assert content =~ "some_other_config: true"

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Claude hooks have been configured")
             end)
    end

    test "handles malformed .claude.exs file gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            nil
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert igniter.issues == []
    end

    test "groups hooks by event type and matcher" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                post_tool_use: [
                  {"format {{tool_input.file_path}}", when: [:write, :edit]},
                  {"compile --warnings-as-errors", when: [:write, :edit, :multi_edit]}
                ],
                pre_tool_use: [
                  {"test --stale", when: "Bash(git commit:*)"}
                ]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      settings = File.read!(".claude/settings.json") |> Jason.decode!()

      assert settings["hooks"]["PreToolUse"]
      assert settings["hooks"]["Stop"]
      assert settings["hooks"]["PostToolUse"]

      pre_hooks = settings["hooks"]["PreToolUse"]
      assert is_list(pre_hooks)

      assert Enum.any?(pre_hooks, fn config ->
               Enum.any?(config["hooks"] || [], fn hook ->
                 String.contains?(hook["command"], ".claude/hooks/wrapper.exs pre_tool_use")
               end)
             end)
    end
  end

  describe "formatter.exs automatic updates" do
    test "automatically adds .claude.exs to existing formatter inputs" do
      igniter =
        test_project(
          files: %{
            ".formatter.exs" => """
            [
              inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
            ]
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".formatter.exs")

      source = Rewrite.source!(igniter.rewrite, ".formatter.exs")
      content = Rewrite.Source.get(source, :content)
      {formatter_config, _} = Code.eval_string(content)

      assert ".claude.exs" in formatter_config[:inputs]
    end

    test "does not modify formatter when .claude.exs already included" do
      igniter =
        test_project(
          files: %{
            ".formatter.exs" => """
            [
              inputs: [".claude.exs", "{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
            ]
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_unchanged(igniter, ".formatter.exs")
    end

    test "adds .claude.exs to formatter with no existing inputs key" do
      igniter =
        test_project(
          files: %{
            ".formatter.exs" => """
            [
              line_length: 120
            ]
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".formatter.exs")

      source = Rewrite.source!(igniter.rewrite, ".formatter.exs")
      content = Rewrite.Source.get(source, :content)
      {formatter_config, _} = Code.eval_string(content)

      assert ".claude.exs" in formatter_config[:inputs]
      assert formatter_config[:line_length] == 120
    end

    test "handles empty inputs list" do
      igniter =
        test_project(
          files: %{
            ".formatter.exs" => """
            [
              inputs: []
            ]
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".formatter.exs")

      source = Rewrite.source!(igniter.rewrite, ".formatter.exs")
      content = Rewrite.Source.get(source, :content)
      {formatter_config, _} = Code.eval_string(content)

      assert formatter_config[:inputs] == [".claude.exs"]
    end
  end

  describe "reporters integration" do
    test "registers all hook events when reporters are configured" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile, :format],
                post_tool_use: [:compile]
              },
              reporters: [
                {:webhook, url: "https://example.com/webhook"}
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = [
        "PreToolUse",
        "PostToolUse",
        "Stop",
        "UserPromptSubmit",
        "Notification",
        "PreCompact",
        "SessionStart"
      ]

      actual_events = Map.keys(settings["hooks"])

      for event <- expected_events do
        assert event in actual_events,
               "Expected #{event} to be registered when reporters are present"
      end

      for event <- expected_events do
        hooks = settings["hooks"][event]
        assert is_list(hooks)
        assert length(hooks) == 1

        [hook_config] = hooks
        assert hook_config["matcher"] == "*"

        [command_config] = hook_config["hooks"]
        assert command_config["type"] == "command"

        expected_command =
          "cd $CLAUDE_PROJECT_DIR && elixir .claude/hooks/wrapper.exs #{Macro.underscore(event)}"

        assert command_config["command"] == expected_command
      end
    end

    test "only registers events with hooks when no reporters are configured" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile, :format],

                pre_tool_use: [{"deps.unlock --check-unused", when: "Bash(git commit:*)"}]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = ["Stop", "PreToolUse"]
      unexpected_events = ["UserPromptSubmit", "Notification", "PreCompact", "SessionStart"]

      actual_events = Map.keys(settings["hooks"])

      for event <- expected_events do
        assert event in actual_events, "Expected #{event} to be registered (has hooks configured)"
      end

      for event <- unexpected_events do
        refute event in actual_events,
               "Did not expect #{event} to be registered (no hooks configured, no reporters)"
      end
    end

    test "empty reporters list still triggers all events registration" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile]
              },
              reporters: []
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = [
        "PreToolUse",
        "PostToolUse",
        "Stop",
        "UserPromptSubmit",
        "Notification",
        "PreCompact",
        "SessionStart"
      ]

      actual_events = Map.keys(settings["hooks"])

      for event <- expected_events do
        assert event in actual_events,
               "Expected #{event} to be registered when reporters key exists (even if empty)"
      end
    end

    test "complex reporters configuration registers all events" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                post_tool_use: [:format]
              },
              reporters: [
                {:webhook, url: "https://example.com/webhook", enabled: true},
                {MyCustomReporter, custom_option: "value"}
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = [
        "PreToolUse",
        "PostToolUse",
        "Stop",
        "UserPromptSubmit",
        "Notification",
        "PreCompact",
        "SessionStart"
      ]

      actual_events = Map.keys(settings["hooks"])

      for event <- expected_events do
        assert event in actual_events,
               "Expected #{event} to be registered with complex reporters config"
      end
    end

    test "no hooks configured but reporters present registers all events" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              reporters: [
                {:webhook, url: "https://example.com/webhook"}
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = [
        "PreToolUse",
        "PostToolUse",
        "Stop",
        "UserPromptSubmit",
        "Notification",
        "PreCompact",
        "SessionStart"
      ]

      actual_events = Map.keys(settings["hooks"])

      for event <- expected_events do
        assert event in actual_events,
               "Expected #{event} to be registered when only reporters are configured"
      end
    end

    test "no hooks and no reporters still creates hooks from Base plugin" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              some_other_config: true
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude/settings.json")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      assert Map.has_key?(settings, "hooks")
      assert Map.has_key?(settings["hooks"], "PostToolUse")
      assert Map.has_key?(settings["hooks"], "PreToolUse")
    end

    test "backward compatibility: existing configs without reporters unchanged" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile, :format],
                post_tool_use: [:compile, :format],
                pre_tool_use: [:compile, :format, :unused_deps],

              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = ["Stop", "PostToolUse", "PreToolUse"]
      unexpected_events = ["UserPromptSubmit", "Notification", "PreCompact", "SessionStart"]

      actual_events = Map.keys(settings["hooks"])

      for event <- expected_events do
        assert event in actual_events,
               "Expected #{event} to be registered (backward compatibility)"
      end

      for event <- unexpected_events do
        refute event in actual_events,
               "Did not expect #{event} to be registered (backward compatibility)"
      end
    end

    test "registers all events when reporters are defined via plugins" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [TestPlugins.WithReporters],
              hooks: %{
                post_tool_use: [:format]
              }
            }
            """
          }
        )
        |> Igniter.assign(:test_mode, true)
        |> Igniter.compose_task("claude.install")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = [
        "PreToolUse",
        "PostToolUse",
        "Stop",
        "UserPromptSubmit",
        "Notification",
        "PreCompact",
        "SessionStart"
      ]

      actual_events = Map.keys(settings["hooks"])

      for event <- expected_events do
        assert event in actual_events,
               "Expected #{event} to be registered when reporters are defined via plugins"
      end
    end
  end

  describe "Phoenix plugin integration" do
    test "Phoenix plugin preserves existing config when Phoenix plugin already present" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Base, Claude.Plugins.Phoenix],
              custom_setting: "preserved_value"
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Phoenix")

      assert String.contains?(content, "custom_setting:")
      assert String.contains?(content, "preserved_value")

      refute String.contains?(content, "mcp_servers:")

      assert_creates(igniter, ".mcp.json")
    end

    test "Phoenix plugin with custom options preserved when installer runs" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [{Claude.Plugins.Phoenix, include_daisyui?: false}],
              auto_install_deps?: true
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "include_daisyui?: false")

      assert String.contains?(content, "auto_install_deps?: true")

      refute String.contains?(content, "mcp_servers:")
      refute String.contains?(content, ":tidewave")

      assert_creates(igniter, ".mcp.json")
    end

    test "installer doesn't duplicate Tidewave when Phoenix plugin already provides it" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Phoenix],
              mcp_servers: [{:tidewave, [port: 5000]}]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "Claude.Plugins.Base"
      assert content =~ "Claude.Plugins.Phoenix"
      assert content =~ "mcp_servers:"
      assert content =~ "tidewave"
      assert content =~ "port: 5000"

      assert_creates(igniter, ".mcp.json")

      source = Rewrite.source!(igniter.rewrite, ".mcp.json")
      content = Rewrite.Source.get(source, :content)
      {:ok, json} = Jason.decode(content)

      assert json["mcpServers"]["tidewave"]["url"] == "http://localhost:5000/tidewave/mcp"
    end

    test "installer merges Phoenix plugin's Tidewave with existing MCP servers" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Phoenix],
              mcp_servers: [:custom_server, :another_server]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude.exs")

      # Include the existing file to read it from the test project  
      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Phoenix")

      assert String.contains?(content, ":custom_server")
      assert String.contains?(content, ":another_server")

      refute String.contains?(content, ":tidewave")

      assert_creates(igniter, ".mcp.json")
    end

    test "Phoenix plugin provides nested_memories and runtime config correctly" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Phoenix],
              nested_memories: %{
                "docs" => ["custom_rule"]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "nested_memories:")
      assert String.contains?(content, "custom_rule")
    end

    test "Phoenix plugin doesn't activate for non-Phoenix projects" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Base, Claude.Plugins.Phoenix],
              custom_setting: "should_be_preserved"
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # because Phoenix plugin returns empty config and no Tidewave is needed
      refute Igniter.changed?(igniter, ".claude.exs")

      refute Igniter.exists?(igniter, ".mcp.json")

      refute Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave")
             end)
    end

    test "Phoenix plugin works with Base plugin hooks without conflicts" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Base, Claude.Plugins.Phoenix],
              hooks: %{
                stop: ["echo 'custom hook'"]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "hooks:")
      assert String.contains?(content, "echo 'custom hook'")

      refute String.contains?(content, "mcp_servers:")

      assert_creates(igniter, ".mcp.json")
    end

    test "installer handles Phoenix plugin + manual Tidewave gracefully" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave MCP server has been configured")
             end)

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      refute String.contains?(content, "mcp_servers:")
      refute String.contains?(content, ":tidewave")

      assert_creates(igniter, ".mcp.json")
    end

    test "Phoenix plugin with custom port option works correctly" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [{Claude.Plugins.Phoenix, port: 8080}]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "port: 8080")

      refute String.contains?(content, "mcp_servers:")
      refute String.contains?(content, "tidewave:")

      assert_creates(igniter, ".mcp.json")

      json_source = Rewrite.source!(igniter.rewrite, ".mcp.json")
      json_content = Rewrite.Source.get(json_source, :content)
      {:ok, json} = Jason.decode(json_content)

      assert json["mcpServers"]["tidewave"]["url"] ==
               "http://localhost:${PORT:-8080}/tidewave/mcp"
    end
  end

  describe "Ash plugin integration" do
    test "automatically adds Ash plugin for Ash projects" do
      igniter =
        ash_test_project()
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Ash")
    end

    test "Ash plugin preserves existing config when Ash plugin already present" do
      igniter =
        ash_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Base, Claude.Plugins.Ash],
              custom_setting: "preserved_value"
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Ash")
      assert String.contains?(content, "custom_setting:")
      assert String.contains?(content, "preserved_value")
    end

    test "Ash plugin with custom options preserved when installer runs" do
      igniter =
        ash_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [{Claude.Plugins.Ash, []}],
              auto_install_deps?: true
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Ash")
      assert String.contains?(content, "auto_install_deps?: true")
    end

    test "Ash plugin doesn't activate for non-Ash projects" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Base, Claude.Plugins.Ash],
              custom_setting: "should_be_preserved"
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # because Ash plugin returns empty config when no Ash dependency
      refute Igniter.changed?(igniter, ".claude.exs")
    end

    test "Ash plugin works with Base plugin hooks without conflicts" do
      igniter =
        ash_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Base, Claude.Plugins.Ash],
              hooks: %{
                stop: ["echo 'custom hook'"]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      refute Igniter.changed?(igniter, ".claude.exs")

      igniter_with_file = Igniter.include_existing_file(igniter, ".claude.exs")
      source = Rewrite.source!(igniter_with_file.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "hooks:")
      assert String.contains?(content, "echo 'custom hook'")
    end

    test "Ash plugin adds correct nested memories configuration" do
      igniter =
        ash_test_project()
        |> Igniter.compose_task("claude.install")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "Claude.Plugins.Ash")
    end

    test "installer handles both Phoenix and Ash plugins together" do
      igniter =
        phx_ash_test_project()
        |> Igniter.compose_task("claude.install")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "Claude.Plugins.Ash")
    end

    test "usage rules for Phoenix and Ash are inlined" do
      igniter =
        phx_ash_test_project()
        |> Igniter.compose_task("claude.install")

      {"usage_rules.sync", args} =
        Enum.find(igniter.tasks, fn {task, _} -> task == "usage_rules.sync" end)

      inline_arg =
        args
        |> Enum.drop_while(&(&1 != "--inline"))
        |> Enum.at(1, "")

      inline_parts = String.split(inline_arg, ",")

      assert "usage_rules:all" in inline_parts
      assert "phoenix" in inline_parts
      assert "ash" in inline_parts
    end

    test "Ash plugin detected during initial template creation" do
      igniter =
        ash_test_project()
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "Claude.Plugins.Ash")
    end

    test "Ash plugin added when running install on existing .claude.exs" do
      igniter =
        ash_test_project(
          files: %{
            ".claude.exs" => """
            %{
              plugins: [Claude.Plugins.Base],
              some_other_config: "value"
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Igniter.changed?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Ash")
      assert String.contains?(content, "some_other_config")
      assert String.contains?(content, "value")
    end
  end

  # Helper functions for Ash project testing
  defp ash_test_project(opts \\ []) do
    app = Keyword.get(opts, :app, :my_app)

    default_files = %{
      "mix.exs" => """
      defmodule MyApp.MixProject do
        use Mix.Project

        def project do
          [
            app: #{inspect(app)},
            version: "0.1.0",
            elixir: "~> 1.14",
            deps: deps()
          ]
        end

        defp deps do
          [
            {:ash, "~> 3.0"}
          ]
        end
      end
      """
    }

    files = Map.merge(default_files, Keyword.get(opts, :files, %{}))
    opts = Keyword.put(opts, :files, files)

    test_project(opts)
  end

  defp phx_ash_test_project(opts \\ []) do
    app = Keyword.get(opts, :app, :my_app)

    default_files = %{
      "mix.exs" => """
      defmodule MyApp.MixProject do
        use Mix.Project

        def project do
          [
            app: #{inspect(app)},
            version: "0.1.0",
            elixir: "~> 1.14",
            deps: deps()
          ]
        end

        defp deps do
          [
            {:phoenix, "~> 1.7"},
            {:ash, "~> 3.0"}
          ]
        end
      end
      """
    }

    files = Map.merge(default_files, Keyword.get(opts, :files, %{}))
    opts = Keyword.put(opts, :files, files)

    test_project(opts)
  end
end
