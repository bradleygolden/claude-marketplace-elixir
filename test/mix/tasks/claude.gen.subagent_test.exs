defmodule Mix.Tasks.Claude.Gen.SubagentTest do
  use ExUnit.Case
  import Igniter.Test
  import Mimic

  defp with_simulated_input(inputs, fun) do
    inputs = List.wrap(inputs)
    input_ref = make_ref()

    Process.put({:test_inputs, input_ref}, inputs)

    stub(IO, :puts, fn _msg -> :ok end)

    stub(IO, :gets, fn _prompt ->
      case Process.get({:test_inputs, input_ref}) do
        [input | rest] ->
          Process.put({:test_inputs, input_ref}, rest)
          input <> "\n"

        [] ->
          :eof
      end
    end)

    fun.()
  end

  describe "claude.gen.subagent interactive flow" do
    test "generates subagent with all inputs provided" do
      inputs = [
        "Test Runner Agent",
        "MUST BE USED for running and analyzing test results",
        "read, grep, bash",
        "# Purpose",
        "You are an expert test runner.",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        igniter
        |> assert_creates(".claude/agents/test-runner-agent.md")
        |> assert_has_notice(
          &String.contains?(&1, "Successfully generated subagent: Test Runner Agent")
        )
        |> assert_has_notice(&String.contains?(&1, "Tools: Read, Grep, Bash"))

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/test-runner-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/^---\nname: test-runner-agent\n/
        assert content =~ ~r/description: MUST BE USED for running and analyzing test results\n/
        assert content =~ ~r/tools: Read, Grep, Bash\n/
        assert content =~ ~r/---\n\n# Purpose\nYou are an expert test runner\./
      end)
    end

    test "generates subagent with default tools when none specified" do
      inputs = [
        "Database Migration Agent",
        "Expert in database migrations",
        "",
        "You are a database migration expert.",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/database-migration-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/tools: Read, Grep, Glob\n/
      end)
    end

    test "warns about task tool and reprompts" do
      inputs = [
        "Delegation Agent",
        "Delegates to other agents",
        "read, task",
        "n",
        "read, grep",
        "You delegate tasks.",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/delegation-agent.md")
        content = Rewrite.Source.get(source, :content)

        refute content =~ ~r/Task/
        assert content =~ ~r/tools: Read, Grep\n/
      end)
    end

    test "handles empty name input" do
      inputs = [
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        igniter
        |> assert_has_issue("Name cannot be empty")
      end)
    end

    test "handles empty description input" do
      inputs = [
        "Valid Agent",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        igniter
        |> assert_has_issue("Description cannot be empty")
      end)
    end

    test "handles single line prompt" do
      inputs = [
        "Test Agent",
        "Test description",
        "",
        "Single line prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/test-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/Single line prompt/
      end)
    end

    test "handles multi-line prompt correctly" do
      inputs = [
        "Complex Agent",
        "Complex agent for testing",
        "",
        "# Purpose",
        "You are a complex agent.",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/complex-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/# Purpose\nYou are a complex agent\./
      end)
    end
  end

  describe "subagent filename generation" do
    test "generates correct filenames for various agent names" do
      test_cases = [
        {"Database Migration Agent", "database-migration-agent.md"},
        {"API Documentation Helper", "api-documentation-helper.md"},
        {"Test_Runner_Agent", "test-runner-agent.md"},
        {"Agent123", "agent123.md"},
        {"Complex   Agent   Name", "complex-agent-name.md"},
        {"!!!Special###Agent!!!", "special-agent.md"},
        {"-Leading-Trailing-", "leading-trailing.md"}
      ]

      for {name, expected_filename} <- test_cases do
        inputs = [name, "Test description", "", "Test prompt", ""]

        with_simulated_input(inputs, fn ->
          igniter =
            test_project()
            |> Igniter.compose_task("claude.gen.subagent", [])

          expected_path = ".claude/agents/#{expected_filename}"
          assert_creates(igniter, expected_path)
        end)
      end
    end
  end

  describe "tool handling" do
    test "generates subagent with correct tool strings in markdown" do
      inputs = [
        "Tool Test Agent",
        "Tests all tools",
        "bash, edit, glob, grep, ls, multi_edit, notebook_edit, notebook_read, read, todo_write, web_fetch, web_search, write",
        "Test prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/tool-test-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~
                 ~r/tools: Bash, Edit, Glob, Grep, LS, MultiEdit, NotebookEdit, NotebookRead, Read, TodoWrite, WebFetch, WebSearch, Write/
      end)
    end

    test "handles various tool input formats" do
      inputs = [
        "Format Test Agent",
        "Tests tool format handling",
        "  read ,  write  ,   edit  , multi_edit, multiedit",
        "Test prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/format-test-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/tools: Read, Write, Edit, MultiEdit/
      end)
    end

    test "ignores invalid tools in input" do
      inputs = [
        "Invalid Tool Agent",
        "Tests invalid tool handling",
        "read, invalid_tool, write, another_bad_tool",
        "Test prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/invalid-tool-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/tools: Read, Write/
        refute content =~ ~r/invalid_tool/
        refute content =~ ~r/another_bad_tool/
      end)
    end
  end

  describe ".claude.exs integration" do
    test "adds subagent to existing .claude.exs file" do
      inputs = [
        "New Agent",
        "New agent description",
        "",
        "Agent prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project(
            files: %{
              ".claude.exs" => """
              %{
                hooks: [
                  Claude.Hooks.PostToolUse.ElixirFormatter
                ],
                subagents: [
                  %{
                    name: "Existing Agent",
                    description: "Existing description",
                    prompt: "Existing prompt",
                    tools: [:read]
                  }
                ]
              }
              """
            }
          )
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude.exs")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/name: "New Agent"/
        assert content =~ ~r/description: "New agent description"/
        assert content =~ ~r/prompt: """/
        assert content =~ ~r/Agent prompt/
        assert content =~ ~r/tools: \[:read, :grep, :glob\]/
      end)
    end

    test "creates new .claude.exs with subagent if none exists" do
      inputs = [
        "First Agent",
        "First agent description",
        "read, write",
        "First agent prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        igniter
        |> assert_creates(".claude.exs")

        source = Rewrite.source!(igniter.rewrite, ".claude.exs")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/%\{\n  hooks: %\{/
        assert content =~ ~r/post_tool_use: \[/
        assert content =~ ~r/subagents: \[/
        assert content =~ ~r/name: "First Agent"/
        assert content =~ ~r/tools: \[:read, :write\]/
      end)
    end

    test "adds subagents list to .claude.exs without one" do
      inputs = [
        "New Agent",
        "Description",
        "",
        "Prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
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
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude.exs")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/subagents: \[/
        assert content =~ ~r/name: "New Agent"/
        assert content =~ ~r/description: "Description"/
      end)
    end

    test "replaces existing subagent with same name" do
      inputs = [
        "Existing Agent",
        "Updated description",
        "bash, grep",
        "Updated prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project(
            files: %{
              ".claude.exs" => """
              %{
                subagents: [
                  %{
                    name: "Existing Agent",
                    description: "Old description",
                    prompt: "Old prompt",
                    tools: [:read]
                  }
                ]
              }
              """
            }
          )
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude.exs")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/description: "Updated description"/
        assert content =~ ~r/tools: \[:bash, :grep\]/
        refute content =~ ~r/Old description/
        refute content =~ ~r/tools: \[:read\]/
      end)
    end

    test "handles empty subagents list" do
      inputs = [
        "First Agent",
        "Description",
        "",
        "Prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
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
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude.exs")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/name: "First Agent"/
        assert content =~ ~r/description: "Description"/
        assert content =~ ~r/subagents: \[/
      end)
    end
  end

  describe "prompt formatting" do
    test "properly escapes triple quotes in prompt" do
      inputs = [
        "Quote Agent",
        "Handles quotes",
        "",
        ~s(This prompt has """ triple quotes),
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude.exs")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/This prompt has/
        assert content =~ ~r/triple quotes/
        assert String.contains?(content, ~s(\\\"\"\"))
      end)
    end

    test "preserves prompt indentation" do
      inputs = [
        "Indented Agent",
        "Has indented prompt",
        "",
        "Line 1",
        "  Indented line",
        "    More indented",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/indented-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/Line 1\n  Indented line\n    More indented/
      end)
    end
  end

  describe "success notice" do
    test "includes all relevant information" do
      inputs = [
        "Test Agent",
        "Test description",
        "read, write, bash",
        "Test prompt",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        igniter
        |> assert_has_notice(&String.contains?(&1, "Successfully generated subagent: Test Agent"))
        |> assert_has_notice(&String.contains?(&1, "Configuration added to: .claude.exs"))
        |> assert_has_notice(
          &String.contains?(&1, "Subagent file created: .claude/agents/test-agent.md")
        )
        |> assert_has_notice(&String.contains?(&1, "Tools: Read, Write, Bash"))
        |> assert_has_notice(&String.contains?(&1, "Next steps:"))
        |> assert_has_notice(&String.contains?(&1, "1. Review the generated subagent"))
        |> assert_has_notice(&String.contains?(&1, "2. Run `mix claude.install`"))
        |> assert_has_notice(&String.contains?(&1, "3. Test delegation"))
        |> assert_has_notice(&String.contains?(&1, "Tips:"))
      end)
    end
  end

  describe "edge cases" do
    test "handles EOF during input gracefully" do
      stub(IO, :puts, fn _msg -> :ok end)
      stub(IO, :gets, fn _prompt -> "\n" end)

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.subagent", [])

      assert Enum.any?(igniter.issues, &String.contains?(&1, "Name cannot be empty"))
    end

    test "confirms task tool inclusion when user says yes" do
      inputs = [
        "Task Agent",
        "Uses task tool",
        "read, task, write",
        "y",
        "Agent with task",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/task-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/tools: Read, Task, Write/
      end)
    end

    test "creates parent directories for agent file" do
      inputs = [
        "Deep Agent",
        "Test deep path",
        "",
        "Deep agent",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        igniter
        |> assert_creates(".claude/agents/deep-agent.md")
      end)
    end

    test "handles special characters in agent name" do
      inputs = [
        "Agent (with) [special] {chars}!",
        "Special char agent",
        "",
        "Special agent",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        igniter
        |> assert_creates(".claude/agents/agent-with-special-chars.md")

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/agent-with-special-chars.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/^name: agent-with-special-chars$/m
      end)
    end

    test "generates subagent with default tools when empty input" do
      inputs = [
        "No Input Tools Agent",
        "Agent with default tools",
        "",
        "Agent with default tools",
        ""
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [])

        source = Rewrite.source!(igniter.rewrite, ".claude/agents/no-input-tools-agent.md")
        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/tools: Read, Grep, Glob/
      end)
    end
  end

  describe "non-interactive mode with flags" do
    test "generates subagent with all flags provided" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.subagent", [
          "--name",
          "test-assistant",
          "--description",
          "Helps with testing",
          "--tools",
          "read,grep,bash",
          "--prompt",
          "You are a testing expert.\nHelp users write and run tests."
        ])

      igniter
      |> assert_creates(".claude/agents/test-assistant.md")
      |> assert_has_notice(
        &String.contains?(&1, "Successfully generated subagent: test-assistant")
      )

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/test-assistant.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/name: test-assistant/
      assert content =~ ~r/description: Helps with testing/
      assert content =~ ~r/tools: Read, Grep, Bash/
      assert content =~ ~r/You are a testing expert/
    end

    test "uses default tools when tools flag is omitted" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.subagent", [
          "--name",
          "minimal-agent",
          "--description",
          "Minimal test agent",
          "--prompt",
          "Simple prompt"
        ])

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/minimal-agent.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/tools: Read, Grep, Glob/
    end

    test "falls back to interactive mode when required flags are missing" do
      inputs = ["Interactive Agent", "Interactive description", "", "Interactive prompt", ""]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.subagent", [
            "--name",
            "ignored-name",
            "--description",
            "ignored-description"
          ])

        igniter
        |> assert_creates(".claude/agents/interactive-agent.md")
      end)
    end

    test "handles multi-line prompts in flags" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.subagent", [
          "--name",
          "multi-line-agent",
          "--description",
          "Agent with complex prompt",
          "--prompt",
          "# Purpose\nYou are an expert.\n\n## Instructions\n1. Be helpful\n2. Be accurate"
        ])

      source = Rewrite.source!(igniter.rewrite, ".claude/agents/multi-line-agent.md")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/# Purpose/
      assert content =~ ~r/## Instructions/
      assert content =~ ~r/1\. Be helpful/
    end

    test "adds subagent to .claude.exs in non-interactive mode" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => "%{\n  subagents: []\n}"
          }
        )
        |> Igniter.compose_task("claude.gen.subagent", [
          "--name",
          "automated-agent",
          "--description",
          "Created by automation",
          "--tools",
          "write,edit",
          "--prompt",
          "Automated agent prompt"
        ])

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/name: "automated-agent"/
      assert content =~ ~r/description: "Created by automation"/
      assert content =~ ~r/tools: \[:write, :edit\]/
    end
  end
end
