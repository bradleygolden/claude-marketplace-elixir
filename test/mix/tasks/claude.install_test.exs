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

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Phoenix project detected!") &&
                 String.contains?(notice, "Tidewave")
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

      assert_unchanged(igniter, ".claude.exs")
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

  # The "hooks with IDs" feature has been removed in favor of simpler atom-based hooks
  # These tests have been removed as they test functionality that no longer exists

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

      assert_creates(igniter, ".claude/agents/ecto-expert.md")
      assert_creates(igniter, ".claude/agents/phoenix-specialist.md")

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

      assert Enum.any?(igniter.warnings, fn warning ->
               String.contains?(warning, "Failed to generate some subagents")
             end)
    end

    test "creates meta agent by default" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(Map.keys(igniter.rewrite.sources), fn path ->
               path == ".claude.exs"
             end)

      claude_exs_source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      claude_exs_content = Rewrite.Source.get(claude_exs_source, :content)
      assert String.contains?(claude_exs_content, "Claude.Plugins.Base")

      {base_config, _} = Code.eval_string(claude_exs_content)
      assert is_map(base_config)
      assert Map.has_key?(base_config, :plugins)

      {:ok, plugin_configs} = Claude.Plugin.load_plugins(base_config.plugins)
      merged_config = Claude.Plugin.merge_configs(plugin_configs ++ [base_config])

      assert Map.has_key?(merged_config, :subagents)
      subagents = Map.get(merged_config, :subagents, [])
      assert is_list(subagents)
      assert length(subagents) > 0

      meta_agent =
        Enum.find(subagents, fn agent ->
          Map.get(agent, :name) == "Meta Agent"
        end)

      assert meta_agent != nil
      assert Map.has_key?(meta_agent, :description)
      assert Map.has_key?(meta_agent, :prompt)
      assert Map.has_key?(meta_agent, :tools)
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

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/test-agent.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~
               ~r/^---\nname: test-agent\ndescription: A test agent for verification\ntools: Read, Grep\n---\n\n/

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

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/no-tools-agent.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~
               ~r/^---\nname: no-tools-agent\ndescription: An agent with no tool restrictions\n---\n\n/

      refute content =~ ~r/tools:/
    end

    test "generates subagents with usage_rules when specified" do
      File.mkdir_p!("deps/ash")

      File.write!(
        "deps/ash/usage-rules.md",
        "# Ash Usage Rules\n\nUse Ash for declarative resources."
      )

      on_exit(fn -> File.rm_rf!("deps/ash") end)

      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Resource Manager",
                  description: "Manages Ash resources",
                  prompt: "You are an expert in Ash Framework.",
                  tools: [:read, :write],
                  usage_rules: [:ash]
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/resource-manager.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "You are an expert in Ash Framework."
      assert content =~ "## Usage Rules"
      assert content =~ "### ash"
      assert content =~ "# Ash Usage Rules"
      assert content =~ "Use Ash for declarative resources."
    end

    test "handles multiple usage_rules for subagents" do
      File.mkdir_p!("deps/ash")
      File.mkdir_p!("deps/phoenix")
      File.write!("deps/ash/usage-rules.md", "# Ash Rules\n\nAsh content.")
      File.write!("deps/phoenix/usage-rules.md", "# Phoenix Rules\n\nPhoenix content.")

      on_exit(fn ->
        File.rm_rf!("deps/ash")
        File.rm_rf!("deps/phoenix")
      end)

      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Full Stack",
                  description: "Full stack expert",
                  prompt: "Base prompt.",
                  usage_rules: [:ash, :phoenix]
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/full-stack.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "## Usage Rules"
      assert content =~ "### ash"
      assert content =~ "# Ash Rules"
      assert content =~ "Ash content."
      assert content =~ "### phoenix"
      assert content =~ "# Phoenix Rules"
      assert content =~ "Phoenix content."
    end

    test "handles string-based usage_rules with sub-rules" do
      File.mkdir_p!("deps/ash/usage-rules")

      File.write!(
        "deps/ash/usage-rules/resources.md",
        "# Resource Rules\n\nResource specific rules."
      )

      on_exit(fn -> File.rm_rf!("deps/ash") end)

      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Resource Expert",
                  description: "Expert in resources",
                  prompt: "Base prompt.",
                  usage_rules: ["ash:resources"]
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/resource-expert.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "## Usage Rules"
      assert content =~ "### ash:resources"
      assert content =~ "Resource specific rules."
    end

    test "handles empty usage_rules list without adding section" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Empty Rules",
                  description: "Has empty rules",
                  prompt: "Base prompt.",
                  usage_rules: []
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/empty-rules.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "Base prompt."
      refute content =~ "## Usage Rules"
    end

    test "gracefully handles missing usage rules files" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Missing Rules",
                  description: "Has missing rules",
                  prompt: "Original prompt.",
                  usage_rules: [:nonexistent, "missing:rule"]
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/missing-rules.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ "Original prompt."
      refute content =~ "## Usage Rules"
    end

    test "validates usage_rules must be a list" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              subagents: [
                %{
                  name: "Invalid Rules",
                  description: "Invalid usage_rules",
                  prompt: "Prompt.",
                  usage_rules: "not_a_list"
                }
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.warnings, fn warning ->
               String.contains?(warning, "usage_rules must be a list") or
                 String.contains?(warning, "Invalid Rules")
             end)
    end
  end

  describe "tidewave MCP configuration" do
    test "automatically installs tidewave for Phoenix projects" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Phoenix project detected!") &&
                 String.contains?(notice, "Automatically adding Tidewave")
             end)
    end

    test "automatically adds tidewave to .claude.exs mcp_servers for Phoenix projects" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".claude.exs")

      source = igniter.rewrite |> Rewrite.source!(".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert String.contains?(content, "mcp_servers:")
      assert String.contains?(content, ":tidewave")
    end

    test "creates .mcp.json automatically for Phoenix projects" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)
      {:ok, json} = Jason.decode(content)

      assert json["mcpServers"]["tidewave"]["type"] == "sse"
      assert json["mcpServers"]["tidewave"]["url"] == "http://localhost:4000/tidewave/mcp"
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

      assert Enum.any?(notices, &String.contains?(&1, "Generated 1 subagent(s)"))
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
                subagent_stop: [:compile, :format],
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

      # The hook system creates dispatcher commands for each event type that has hooks
      # Hooks with when: conditions are still processed but filtered at runtime
      assert settings["hooks"]["PreToolUse"]
      assert settings["hooks"]["Stop"]
      assert settings["hooks"]["SubagentStop"]

      # Each event type should have its corresponding dispatcher command
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

  describe "command installation" do
    test "does not block installation when commands already exist" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: %{
                stop: [:compile]
              }
            }
            """,
            ".claude/commands/mix/deps.md" => """
            ---
            description: Existing command
            ---
            # Deps
            """
          }
        )

      result = Igniter.compose_task(igniter, "claude.install", ["--yes"])

      assert length(result.issues) == 0
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
        "SubagentStop",
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
                subagent_stop: [:compile],
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

      expected_events = ["Stop", "SubagentStop", "PreToolUse"]
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
        "SubagentStop",
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
        "SubagentStop",
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
        "SubagentStop",
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

    test "no hooks and no reporters creates empty settings" do
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

      refute Map.has_key?(settings, "hooks")
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
                subagent_stop: [:compile, :format]
              }
            }
            """
          }
        )
        |> Igniter.compose_task("claude.install")

      source = igniter.rewrite |> Rewrite.source!(".claude/settings.json")
      content = Rewrite.Source.get(source, :content)
      settings = Jason.decode!(content)

      expected_events = ["Stop", "PostToolUse", "PreToolUse", "SubagentStop"]
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
        "SubagentStop",
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
    test "Phoenix plugin preserves existing config when installer adds Tidewave" do
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

      # Should modify .claude.exs to add mcp_servers while preserving existing config
      assert Igniter.changed?(igniter, ".claude.exs")

      # The final .claude.exs should have ALL original config plus new mcp_servers
      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      # Should preserve original plugins configuration
      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Base")
      assert String.contains?(content, "Claude.Plugins.Phoenix")

      # Should preserve custom settings
      assert String.contains?(content, "custom_setting:")
      assert String.contains?(content, "preserved_value")

      # Should add mcp_servers from installer
      assert String.contains?(content, "mcp_servers:")
      assert String.contains?(content, ":tidewave")

      # Should create .mcp.json with tidewave configuration
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

      # Should modify .claude.exs to add mcp_servers while preserving plugin options
      assert Igniter.changed?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      # Should preserve plugin with custom options
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "include_daisyui?: false")

      # Should preserve other settings
      assert String.contains?(content, "auto_install_deps?: true")

      # Should add mcp_servers from installer
      assert String.contains?(content, "mcp_servers:")
      assert String.contains?(content, ":tidewave")

      # Should create MCP configuration
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

      # Should NOT modify .claude.exs since Tidewave already configured
      assert_unchanged(igniter, ".claude.exs")

      # Should create .mcp.json with the existing custom port
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

      # Should modify .claude.exs to add Tidewave to existing mcp_servers
      assert Igniter.changed?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      # Should preserve plugin configuration
      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Phoenix")

      # Should have all MCP servers (existing + Tidewave from installer)
      assert String.contains?(content, ":custom_server")
      assert String.contains?(content, ":another_server")
      assert String.contains?(content, ":tidewave")

      # Should NOT have duplicate Tidewave entries
      tidewave_count =
        content
        |> String.graphemes()
        |> Enum.chunk_every(8, 1, :discard)
        |> Enum.map(&Enum.join/1)
        |> Enum.count(&String.contains?(&1, "tidewave"))

      assert tidewave_count == 1
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

      # Should add mcp_servers while preserving everything else
      assert Igniter.changed?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      # Should preserve plugin and existing nested_memories
      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "nested_memories:")
      assert String.contains?(content, "custom_rule")

      # Should have tasks for nested memories generation (Phoenix plugin provides more memories)
      assert Enum.any?(igniter.tasks, fn {task_name, _args} ->
               task_name == "nested_memories.generate"
             end)
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

      # For non-Phoenix projects, installer should not modify .claude.exs 
      # because Phoenix plugin returns empty config and no Tidewave is needed
      refute Igniter.changed?(igniter, ".claude.exs")

      # Should NOT create .mcp.json since no Phoenix detected
      refute Igniter.exists?(igniter, ".mcp.json")

      # Should NOT have Tidewave-related notices
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

      # Should merge plugin configs and preserve custom hooks
      assert Igniter.changed?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      # Should preserve everything including custom hooks
      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "hooks:")
      assert String.contains?(content, "echo 'custom hook'")
      assert String.contains?(content, "mcp_servers:")
    end

    test "installer handles Phoenix plugin + manual Tidewave gracefully" do
      igniter =
        phx_test_project()
        |> Igniter.compose_task("claude.install")

      # Should detect Phoenix and add Tidewave automatically
      assert Enum.any?(igniter.notices, fn notice ->
               String.contains?(notice, "Phoenix project detected!")
             end)

      # When Phoenix plugin is added later, it should not conflict
      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)
      assert String.contains?(content, "mcp_servers:")
      assert String.contains?(content, ":tidewave")
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

      # Should add mcp_servers with custom port while preserving plugin
      assert Igniter.changed?(igniter, ".claude.exs")

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      # Should preserve plugin configuration
      assert String.contains?(content, "plugins:")
      assert String.contains?(content, "Claude.Plugins.Phoenix")
      assert String.contains?(content, "port: 8080")

      # Should add tidewave with custom port preserving environment variable capability
      assert String.contains?(content, "mcp_servers:")
      assert String.contains?(content, "tidewave:")
      assert String.contains?(content, "\"${PORT:-8080}\"")

      # Should have tidewave.install task
      assert Enum.any?(igniter.tasks, fn {task_name, _args} ->
               task_name == "tidewave.install"
             end)
    end
  end
end
