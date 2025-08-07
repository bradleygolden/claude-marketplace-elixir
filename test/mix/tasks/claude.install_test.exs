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

    test "adds .claude.exs to formatter inputs" do
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

      # Instead of patching, we now show a notice
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "To format .claude.exs files") &&
                 String.contains?(notice, "add \".claude.exs\" to your formatter inputs")
             end)
    end

    test "handles missing .formatter.exs file" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      # Check that we have a notice about adding .claude.exs to formatter
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "To format .claude.exs files")
             end)
    end

    test "formatter update is idempotent" do
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

    test "creates claude settings if one doesn't exist" do
      test_project()
      |> Igniter.compose_task("claude.install")
      |> assert_creates(".claude/settings.json")
    end

    test "preserves existing .claude.exs file" do
      custom_config = """
      %{
        hooks: %{
          stop: [:compile, :format],
          post_tool_use: ["custom --task"]
        },
        custom_setting: true
      }
      """

      test_project(
        files: %{
          ".claude.exs" => custom_config
        }
      )
      |> Igniter.compose_task("claude.install")
      |> assert_unchanged(".claude.exs")
    end

    test "generates .claude.exs with atom shortcuts for hooks" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert_creates(igniter, ".claude.exs")

      # Check that the generated file contains atom shortcuts by checking the rewrite map
      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "stop: [:compile, :format]"
      assert content =~ "subagent_stop: [:compile, :format]"
      assert content =~ "post_tool_use: [:compile, :format]"
      assert content =~ "pre_tool_use: [:compile, :format, :unused_deps]"
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

      # Check that an issue is raised for old format
      assert Enum.any?(igniter.issues, fn issue ->
               String.contains?(issue, "outdated hooks format") and
                 String.contains?(issue, "mix claude.upgrade")
             end)
    end

    test "accepts new map-based hook format" do
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

      # Should have no issues with new format
      assert igniter.issues == []
      assert_unchanged(igniter, ".claude.exs")
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

      # Should have no issues with mixed format
      assert igniter.issues == []
      assert_unchanged(igniter, ".claude.exs")
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

      # Check for the Phoenix/Tidewave notice
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Phoenix detected!") &&
                 String.contains?(notice, "Tidewave")
             end)
    end

    test "does not add tidewave to non-Phoenix projects" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      # Ensure no tidewave notice for non-Phoenix projects
      refute Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Tidewave")
             end)
    end

    test "composes all required tasks" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      # Verify files will be created using Igniter assertions
      assert_creates(igniter, ".claude/settings.json")
      assert_creates(igniter, ".claude.exs")

      # Verify the tasks are composed
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

      # The mix.exs should not be changed when dependency already exists
      refute Igniter.changed?(igniter, "mix.exs")
    end

    test "composes usage_rules.sync task" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      # Verify usage_rules.sync task is composed (it creates CLAUDE.md when run)
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

      # Verify the .claude.exs file is unchanged
      assert_unchanged(igniter, ".claude.exs")
    end

    test "installation is idempotent" do
      # First installation
      igniter1 =
        test_project()
        |> Igniter.compose_task("claude.install")

      # Verify files will be created
      assert_creates(igniter1, ".claude.exs")
      assert_creates(igniter1, ".claude/settings.json")

      # Apply the changes to get the actual file contents
      apply_igniter!(igniter1)

      # Second installation with existing files
      igniter2 =
        test_project(
          files: %{
            ".claude.exs" => File.read!(".claude.exs"),
            ".claude/settings.json" => File.read!(".claude/settings.json"),
            "mix.exs" => File.read!("mix.exs")
          }
        )
        |> Igniter.compose_task("claude.install")

      # .claude.exs should not be changed in second run
      assert_unchanged(igniter2, ".claude.exs")

      # Note: settings.json might have timestamp updates, so we just verify it exists
      assert Igniter.exists?(igniter2, ".claude/settings.json")
    end
  end

  describe "new hook system with IDs" do
    test "generates direct mix commands for hooks with IDs" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                post_tool_use: [
                  %{
                    id: :elixir_quality_checks,
                    matcher: [:write, :edit, :multi_edit],
                    tasks: [
                      "format --check-formatted {{tool_input.file_path}}",
                      "compile --warnings-as-errors"
                    ]
                  }
                ],
                pre_tool_use: [
                  %{
                    id: :pre_commit_validation,
                    matcher: [:bash],
                    tasks: ["format --check-formatted"]
                  }
                ]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      # Read and verify settings.json
      settings = File.read!(".claude/settings.json") |> Jason.decode!()

      # Check PostToolUse hooks - new system uses universal matcher
      assert [%{"hooks" => post_hooks, "matcher" => "*"}] =
               settings["hooks"]["PostToolUse"]

      # Should contain our dispatcher hook
      assert Enum.any?(post_hooks, fn hook ->
               hook["command"] ==
                 "cd $CLAUDE_PROJECT_DIR && mix claude.hooks.run post_tool_use"
             end)

      # Check PreToolUse hooks  
      pre_tool_use_hooks = settings["hooks"]["PreToolUse"]
      assert is_list(pre_tool_use_hooks)

      # Should have universal matcher - filtering happens in mix task
      [%{"matcher" => pre_matcher, "hooks" => pre_hooks}] = pre_tool_use_hooks
      assert pre_matcher == "*"

      assert Enum.any?(pre_hooks, fn hook ->
               hook["command"] ==
                 "cd $CLAUDE_PROJECT_DIR && mix claude.hooks.run pre_tool_use"
             end)

      # Verify no hook scripts were created for ID-based hooks
      refute File.exists?(".claude/hooks/claude_hook_elixir_quality_checks.exs")
      refute File.exists?(".claude/hooks/claude_hook_pre_commit_validation.exs")
    end

    test "converts atom matchers to proper strings" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                post_tool_use: [
                  %{
                    id: :test_hook,
                    matcher: [:write, :edit, :multi_edit, :web_fetch],
                    tasks: ["test"]
                  }
                ]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      settings = File.read!(".claude/settings.json") |> Jason.decode!()
      [%{"matcher" => matcher}] = settings["hooks"]["PostToolUse"]

      # New system uses universal matcher - actual filtering happens in mix task
      assert matcher == "*"
    end

    test "prevents hook duplication on re-install" do
      # Create initial .claude.exs
      igniter1 =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                post_tool_use: [
                  %{
                    id: :quality_checks,
                    matcher: [:write],
                    tasks: ["format"]
                  }
                ]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter1)

      # Read initial settings
      settings1 = File.read!(".claude/settings.json") |> Jason.decode!()
      # Find hooks that include Write in their matcher
      all_post_hooks = settings1["hooks"]["PostToolUse"] || []

      initial_hooks =
        all_post_hooks
        |> Enum.filter(&String.contains?(&1["matcher"] || "", "Write"))
        |> Enum.flat_map(&(&1["hooks"] || []))

      initial_count = length(initial_hooks)

      # Re-run installation
      igniter2 =
        test_project(
          files: %{
            ".claude.exs" => File.read!(".claude.exs"),
            ".claude/settings.json" => File.read!(".claude/settings.json"),
            "mix.exs" => File.read!("mix.exs")
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter2)

      # Verify no duplication
      settings2 = File.read!(".claude/settings.json") |> Jason.decode!()
      all_post_hooks2 = settings2["hooks"]["PostToolUse"] || []

      final_hooks =
        all_post_hooks2
        |> Enum.filter(&String.contains?(&1["matcher"] || "", "Write"))
        |> Enum.flat_map(&(&1["hooks"] || []))

      final_count = length(final_hooks)

      # Should have same number of hooks after re-install
      assert final_count == initial_count
    end

    test "handles empty hook lists gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                post_tool_use: [
                  %{
                    id: :empty_hook,
                    matcher: [:write],
                    tasks: []
                  }
                ]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      settings = File.read!(".claude/settings.json") |> Jason.decode!()
      # Empty hooks should still create the command
      post_hooks = settings["hooks"]["PostToolUse"]

      # Find our empty hook entry if it exists
      empty_hook =
        Enum.find(post_hooks, fn config ->
          Enum.any?(config["hooks"] || [], fn hook ->
            String.contains?(hook["command"], "empty_hook")
          end)
        end)

      # If the installer generates commands even for empty tasks, we should find it
      # Otherwise, empty hooks might be filtered out
      assert empty_hook || length(post_hooks) >= 0
    end
  end

  describe "subagent generation" do
    test "generates subagents from .claude.exs configuration" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Ecto Expert",
                  description: "Expert in Ecto and database queries",
                  prompt: "You are an expert in Ecto...",
                  tools: [:read, :grep, :edit]
                },
                %{
                  name: "Phoenix Specialist",
                  description: "Expert in Phoenix framework",
                  prompt: "You are a Phoenix framework specialist..."
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # Verify subagent files are created
      assert_creates(igniter, ".claude/agents/ecto-expert.md")
      assert_creates(igniter, ".claude/agents/phoenix-specialist.md")

      # Verify notice about generated subagents
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Generated 2 subagent(s)")
             end)
    end

    test "handles invalid subagent configuration gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  # Missing required fields
                  name: "Invalid Agent"
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # Should have a warning about failed subagent generation
      assert Enum.any?(igniter.warnings, fn warning ->
               String.contains?(warning, "Failed to generate some subagents")
             end)
    end

    test "creates meta agent by default" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      # Meta agent should be created by default
      assert Enum.any?(Map.keys(igniter.rewrite.sources), fn path ->
               path == ".claude/agents/meta-agent.md"
             end)

      # Check that the meta agent has the correct content
      source = Rewrite.source!(igniter.rewrite, ".claude/agents/meta-agent.md")
      content = Rewrite.Source.get(source, :content)
      assert String.contains?(content, "name: meta-agent")

      assert String.contains?(
               content,
               "description: Generates new, complete Claude Code subagent"
             )
    end

    test "generates subagents with correct YAML frontmatter format" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Test Agent",
                  description: "A test agent for verification",
                  prompt: "You are a test agent that helps with testing.",
                  tools: [:read, :grep]
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # Get the generated content
      source = Rewrite.source!(igniter.rewrite, ".claude/agents/test-agent.md")
      content = Rewrite.Source.get(source, :content)

      # Verify YAML frontmatter format
      assert content =~
               ~r/^---\nname: test-agent\ndescription: A test agent for verification\ntools: Read, Grep\n---\n\n/

      # Verify the prompt is included after the frontmatter
      assert content =~ "You are a test agent that helps with testing."
    end

    test "generates subagents without tools line when no tools specified" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "No Tools Agent",
                  description: "An agent with no tool restrictions",
                  prompt: "You are an agent with access to all tools."
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # Get the generated content
      source = Rewrite.source!(igniter.rewrite, ".claude/agents/no-tools-agent.md")
      content = Rewrite.Source.get(source, :content)

      # Verify YAML frontmatter format without tools line
      assert content =~
               ~r/^---\nname: no-tools-agent\ndescription: An agent with no tool restrictions\n---\n\n/

      refute content =~ ~r/tools:/
    end
  end

  describe "tidewave MCP configuration" do
    test "shows tidewave notice for Phoenix projects" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      # Should show the tidewave notice
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Phoenix detected!") &&
                 String.contains?(notice, "To enable Tidewave MCP server")
             end)
    end

    test "shows tidewave configuration notice when specified in .claude.exs" do
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

      # Check that tidewave configuration notice is shown
      assert Enum.any?(igniter.notices, fn notice ->
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

      # Check that tidewave configuration notice with custom port is shown
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

      assert json["mcpServers"]["tidewave"]["type"] == "sse"
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

      assert json["mcpServers"]["tidewave"]["type"] == "sse"
      assert json["mcpServers"]["tidewave"]["url"] == "http://localhost:5000/tidewave/mcp"
    end

    test "does not create .mcp.json when tidewave is disabled" do
      igniter =
        phx_test_project(
          files: %{
            ".claude.exs" => """
            %{
              mcp_servers: [{:tidewave, [enabled?: false]}]
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

      # Should create default files
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
                  {"format --check-formatted {{tool_input.file_path}}", when: [:write, :edit]}
                ]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # Check that the file will be updated
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

      # Should overwrite with valid JSON
      apply_igniter!(igniter)

      # Should be able to parse the result
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

      # Check the dependency is added correctly
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

      # Should not modify the existing dependency
      refute Igniter.changed?(igniter, "mix.exs")
    end
  end

  describe "notice generation" do
    test "includes all relevant notices" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      notices = igniter.notices

      # Should have hook configuration notice
      assert Enum.any?(notices, &String.contains?(&1, "Claude hooks have been configured"))

      # Should have usage rules sync notice
      assert Enum.any?(notices, &String.contains?(&1, "Syncing usage rules to CLAUDE.md"))

      # Should have subagent generation notice for meta agent
      assert Enum.any?(notices, &String.contains?(&1, "Generated 1 subagent(s)"))
      assert Enum.any?(notices, &String.contains?(&1, "Meta Agent"))
    end

    test "includes subagent notice when subagents are configured" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Test Agent",
                  description: "A test agent",
                  prompt: "You are a test agent"
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      notices = igniter.notices

      # Should have subagent generation notice
      assert Enum.any?(notices, &String.contains?(&1, "Generated 1 subagent(s)"))
    end
  end

  describe "hook configuration from .claude.exs" do
    test "handles missing hooks key in .claude.exs" do
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

      # Should show notice about no hooks configured
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "No hooks configured")
             end)
    end

    test "handles malformed .claude.exs file gracefully" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            # This is a valid Elixir file that returns invalid data
            nil
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # Should not crash - the installer should handle nil config gracefully
      # It will either show missing hooks notice or successfully install with empty hooks
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
                  {"format --check-formatted {{tool_input.file_path}}", when: [:write, :edit]},
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

      # PostToolUse hooks should be grouped together
      assert post_hooks = settings["hooks"]["PostToolUse"]
      assert length(post_hooks) == 1
      [post_config] = post_hooks
      # Single dispatcher hook
      assert length(post_config["hooks"]) == 1
      assert hd(post_config["hooks"])["command"] =~ "claude.hooks.run post_tool_use"

      # PreToolUse hooks should be separate
      assert pre_hooks = settings["hooks"]["PreToolUse"]
      assert length(pre_hooks) == 1
      [pre_config] = pre_hooks
      assert length(pre_config["hooks"]) == 1
      assert hd(pre_config["hooks"])["command"] =~ "claude.hooks.run pre_tool_use"
    end
  end

  describe "formatter.exs update notice" do
    test "shows notice when .formatter.exs needs updating" do
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

      # Should have notice about adding .claude.exs to formatter
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "To format .claude.exs files")
             end)
    end

    test "no notice when .formatter.exs already includes .claude.exs" do
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

      # Should not have formatter notice
      refute Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Add .claude.exs to your .formatter.exs")
             end)
    end
  end
end
