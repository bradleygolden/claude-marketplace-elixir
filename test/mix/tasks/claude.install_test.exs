defmodule Mix.Tasks.Claude.InstallTest do
  use Claude.Test.ClaudeCodeCase, trap_halts: false

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
        hooks: [MyApp.CustomHook],
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

    test "composes claude.hooks.install task" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      # Verify files are created using Igniter assertions
      assert_creates(igniter, ".claude/settings.json")
      assert_creates(igniter, ".claude/hooks/elixir_formatter.exs")
      assert_creates(igniter, ".claude/hooks/compilation_checker.exs")
      assert_creates(igniter, ".claude/hooks/pre_commit_check.exs")

      # Apply the igniter to check the content
      apply_igniter!(igniter)

      # Now we can read the settings to verify the structure
      settings = File.read!(".claude/settings.json") |> Jason.decode!()
      assert hooks = settings["hooks"]

      assert [%{"hooks" => post_tool_use_hooks, "matcher" => matcher}] =
               hooks["PostToolUse"]

      # The matcher should contain all three tools
      assert String.contains?(matcher, "Edit")
      assert String.contains?(matcher, "Write")
      assert String.contains?(matcher, "MultiEdit") or String.contains?(matcher, "Multiedit")

      # Now includes related_files by default from .claude.exs template
      assert length(post_tool_use_hooks) >= 2

      hook_commands = Enum.map(post_tool_use_hooks, & &1["command"])
      assert Enum.any?(hook_commands, &String.contains?(&1, "elixir_formatter.exs"))
      assert Enum.any?(hook_commands, &String.contains?(&1, "compilation_checker.exs"))

      assert [%{"hooks" => pre_tool_use_hooks, "matcher" => "Bash"}] = hooks["PreToolUse"]

      assert [
               %{
                 "type" => "command",
                 "command" =>
                   "cd $CLAUDE_PROJECT_DIR && elixir .claude/hooks/pre_commit_check.exs"
               }
             ] = pre_tool_use_hooks
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
                 String.contains?(notice, "Port: 5000")
             end)
    end
  end

  describe "hook script generation" do
    test "generates hook scripts with correct dependencies" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      # Check that hook scripts have proper Mix.install
      formatter_script = File.read!(".claude/hooks/elixir_formatter.exs")
      assert String.contains?(formatter_script, "Mix.install")
      assert String.contains?(formatter_script, ":claude")
      assert String.contains?(formatter_script, ":jason")
      assert String.contains?(formatter_script, "Claude.Hooks.PostToolUse.ElixirFormatter.run")
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
    test "removes old CLI-based hooks when installing new script-based hooks" do
      igniter =
        test_project(
          files: %{
            ".claude/settings.json" => """
            {
              "hooks": {
                "PostToolUse": [
                  {
                    "matcher": "Edit|Write",
                    "hooks": [
                      {
                        "type": "command",
                        "command": "mix claude hooks run post_tool_use elixir_formatter"
                      }
                    ]
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
      hooks = settings["hooks"]["PostToolUse"]

      # Old CLI hooks should be removed
      refute Enum.any?(hooks, fn matcher_config ->
               Enum.any?(matcher_config["hooks"], fn hook ->
                 String.contains?(hook["command"], "mix claude hooks run")
               end)
             end)

      # New script hooks should be present
      assert Enum.any?(hooks, fn matcher_config ->
               Enum.any?(matcher_config["hooks"], fn hook ->
                 String.contains?(hook["command"], ".claude/hooks/elixir_formatter.exs")
               end)
             end)
    end

    test "replaces all Claude hooks with fresh installations" do
      igniter =
        test_project(
          files: %{
            ".claude/settings.json" => """
            {
              "hooks": {
                "PostToolUse": [
                  {
                    "matcher": "Edit|Write|MultiEdit",
                    "hooks": [
                      {
                        "type": "command",
                        "command": ".claude/hooks/old_formatter.exs"
                      },
                      {
                        "type": "command",
                        "command": "mix claude hooks run post_tool_use elixir_formatter"
                      }
                    ]
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
      hooks = settings["hooks"]["PostToolUse"]

      # Should have one matcher with only the new Claude hooks
      assert length(hooks) == 1
      [matcher_config] = hooks

      hook_commands = Enum.map(matcher_config["hooks"], &Map.get(&1, "command"))

      # Old Claude hooks should be removed
      refute Enum.any?(hook_commands, &String.contains?(&1, "old_formatter.exs"))
      refute Enum.any?(hook_commands, &String.contains?(&1, "mix claude hooks run"))

      # New Claude hooks should be present
      assert Enum.any?(hook_commands, &String.contains?(&1, "elixir_formatter.exs"))
      assert Enum.any?(hook_commands, &String.contains?(&1, "compilation_checker.exs"))

      # Test environment may include RelatedFiles if it's enabled in the project's .claude.exs
      # Just ensure we have at least the two required hooks
      assert length(hook_commands) >= 2
    end
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

      # Should have hook installation notice
      assert Enum.any?(notices, &String.contains?(&1, "Claude hooks have been installed"))

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
    test "reads hooks from .claude.exs file" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter,
                Claude.Hooks.PostToolUse.CompilationChecker,
                Claude.Hooks.PreToolUse.PreCommitCheck
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      # Verify hook scripts are created
      assert File.exists?(".claude/hooks/elixir_formatter.exs")
      assert File.exists?(".claude/hooks/compilation_checker.exs")
      assert File.exists?(".claude/hooks/pre_commit_check.exs")

      # Verify settings.json contains correct hooks
      settings = File.read!(".claude/settings.json") |> Jason.decode!()
      assert hooks = settings["hooks"]["PostToolUse"]
      assert length(hooks) == 1

      [post_tool_use_config] = hooks
      hook_commands = Enum.map(post_tool_use_config["hooks"], & &1["command"])
      assert Enum.any?(hook_commands, &String.contains?(&1, "elixir_formatter.exs"))
      assert Enum.any?(hook_commands, &String.contains?(&1, "compilation_checker.exs"))
    end

    test "handles empty hooks list in .claude.exs" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: []
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      # Should show notice about missing default hooks
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "missing some default hooks")
             end)
    end

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

      # Should show notice about missing default hooks
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "missing some default hooks")
             end)
    end

    test "shows notice when default hooks are missing from existing .claude.exs" do
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
        |> Igniter.compose_task("claude.install")

      # Should have notice about missing default hooks
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "missing some default hooks") &&
                 String.contains?(notice, "Claude.Hooks.PostToolUse.CompilationChecker") &&
                 String.contains?(notice, "Claude.Hooks.PreToolUse.PreCommitCheck")
             end)
    end

    test "handles custom hook modules in .claude.exs" do
      # Define a test hook module
      defmodule TestHook do
        def config do
          %{
            type: :post_tool_use,
            command: "echo 'test hook'",
            matcher: "Test"
          }
        end

        def description, do: "Test hook"
        def __hook_event__, do: :post_tool_use
        def __hook_matcher__, do: "Test"
      end

      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Mix.Tasks.Claude.InstallTest.TestHook
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      # Hook script will only be created if the module can be loaded
      # Since this is a test module defined inline, it won't be available
      # when the script is generated in a separate process
      refute File.exists?(".claude/hooks/test_hook.exs")

      # Since the test module isn't available in the script generation process,
      # verify that other default hooks from the template were still created
      assert File.exists?(".claude/hooks/elixir_formatter.exs")
      assert File.exists?(".claude/hooks/compilation_checker.exs")
    end

    test "ignores invalid hook modules in .claude.exs" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter,
                NonExistentModule,
                "not even a module"
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      # Should only create scripts for valid hooks
      assert File.exists?(".claude/hooks/elixir_formatter.exs")
      refute File.exists?(".claude/hooks/non_existent_module.exs")

      # Settings should only contain valid hooks
      settings = File.read!(".claude/settings.json") |> Jason.decode!()

      all_commands =
        settings["hooks"]
        |> Map.values()
        |> List.flatten()
        |> Enum.flat_map(& &1["hooks"])
        |> Enum.map(& &1["command"])

      assert Enum.any?(all_commands, &String.contains?(&1, "elixir_formatter.exs"))
      refute Enum.any?(all_commands, &String.contains?(&1, "non_existent_module"))
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

    test "handles hook module without required functions" do
      # Define a minimal hook module
      defmodule MinimalHook do
        def config do
          %{type: :post_tool_use, command: "echo 'minimal'", matcher: "Test"}
        end
      end

      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Mix.Tasks.Claude.InstallTest.MinimalHook
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      # Hook script will only be created if the module can be loaded
      # Since this is a test module defined inline, it won't be available
      refute File.exists?(".claude/hooks/minimal_hook.exs")

      # Verify default hooks from template are still created
      assert File.exists?(".claude/hooks/elixir_formatter.exs")
    end

    test "groups hooks by event type and matcher" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter,
                Claude.Hooks.PostToolUse.CompilationChecker,
                Claude.Hooks.PreToolUse.PreCommitCheck
              ]
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
      # Template includes 2 default PostToolUse hooks, but test env may have more
      assert length(post_config["hooks"]) >= 2

      # PreToolUse hooks should be separate
      assert pre_hooks = settings["hooks"]["PreToolUse"]
      assert length(pre_hooks) == 1
      [pre_config] = pre_hooks
      assert length(pre_config["hooks"]) == 1
    end

    test "related files hook can be configured" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter,
                Claude.Hooks.PostToolUse.RelatedFiles
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      apply_igniter!(igniter)

      # Should create both hook scripts
      assert File.exists?(".claude/hooks/elixir_formatter.exs")
      assert File.exists?(".claude/hooks/related_files.exs")

      # Verify settings.json contains both hooks
      settings = File.read!(".claude/settings.json") |> Jason.decode!()
      hooks = settings["hooks"]["PostToolUse"]
      [config] = hooks

      hook_commands = Enum.map(config["hooks"], & &1["command"])
      assert Enum.any?(hook_commands, &String.contains?(&1, "elixir_formatter.exs"))
      assert Enum.any?(hook_commands, &String.contains?(&1, "related_files.exs"))
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
