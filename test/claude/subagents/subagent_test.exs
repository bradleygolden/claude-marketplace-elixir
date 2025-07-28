defmodule Claude.Subagents.SubagentTest do
  use ExUnit.Case, async: true
  alias Claude.Subagents.Subagent

  describe "new/1" do
    test "creates struct with atom keys" do
      attrs = %{
        name: "code_reviewer",
        description: "Reviews code for quality",
        prompt: "You are a code reviewer",
        tools: [:read, :grep, :glob]
      }

      subagent = Subagent.new(attrs)

      assert subagent.name == "code_reviewer"
      assert subagent.description == "Reviews code for quality"
      assert subagent.prompt == "You are a code reviewer"
      assert subagent.tools == [:read, :grep, :glob]
    end

    test "creates struct with string keys" do
      attrs = %{
        "name" => "test_runner",
        "description" => "Runs tests",
        "prompt" => "You run tests",
        "tools" => ["Bash", "Read", "Edit"]
      }

      subagent = Subagent.new(attrs)

      assert subagent.name == "test_runner"
      assert subagent.description == "Runs tests"
      assert subagent.prompt == "You run tests"
      assert subagent.tools == [:bash, :read, :edit]
    end

    test "handles comma-separated tools string" do
      attrs = %{
        name: "debugger",
        description: "Debug issues",
        prompt: "You debug code",
        tools: "Read, Grep, Bash"
      }

      subagent = Subagent.new(attrs)

      assert subagent.name == "debugger"
      assert subagent.tools == [:read, :grep, :bash]
    end

    test "handles nil tools" do
      attrs = %{
        name: "minimal",
        description: "Minimal agent",
        prompt: "Just a prompt"
      }

      subagent = Subagent.new(attrs)

      assert subagent.tools == []
    end

    test "filters out invalid tools" do
      attrs = %{
        name: "mixed",
        description: "Has invalid tools",
        prompt: "Some prompt",
        tools: ["Read", "InvalidTool", "Grep", "UnknownTool"]
      }

      subagent = Subagent.new(attrs)

      assert subagent.tools == [:read, :grep]
    end

    test "handles tools with extra whitespace" do
      attrs = %{
        name: "whitespace",
        description: "Test whitespace handling",
        prompt: "Testing",
        tools: " Read , Grep , Bash "
      }

      subagent = Subagent.new(attrs)

      assert subagent.tools == [:read, :grep, :bash]
    end

    test "preserves tool atoms when already atoms" do
      attrs = %{
        name: "atom_tools",
        description: "Already has atom tools",
        prompt: "Testing atoms",
        tools: [:web_fetch, :web_search, :todo_write]
      }

      subagent = Subagent.new(attrs)

      assert subagent.tools == [:web_fetch, :web_search, :todo_write]
    end

    test "handles plugins configuration" do
      attrs = %{
        name: "with_plugins",
        description: "Has plugins",
        prompt: "Test prompt",
        tools: [:read],
        plugins: [{TestPlugin, %{option: "value"}}]
      }

      subagent = Subagent.new(attrs)

      assert subagent.plugins == [{TestPlugin, %{option: "value"}}]
    end

    test "filters invalid plugin configurations" do
      attrs = %{
        name: "invalid_plugins",
        description: "Has invalid plugins",
        prompt: "Test prompt",
        plugins: [
          {TestPlugin, %{valid: true}},
          "invalid",
          {TestPlugin, "not a map"},
          nil
        ]
      }

      subagent = Subagent.new(attrs)

      assert subagent.plugins == [{TestPlugin, %{valid: true}}]
    end

    test "handles nil plugins" do
      attrs = %{
        name: "no_plugins",
        description: "No plugins",
        prompt: "Test prompt"
      }

      subagent = Subagent.new(attrs)

      assert subagent.plugins == []
    end
  end

  describe "tools_to_strings/1" do
    test "converts tool atoms to Claude Code strings" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "test",
        tools: [:bash, :read, :multi_edit]
      }

      result = Subagent.tools_to_strings(subagent)

      assert result == ["Bash", "Read", "MultiEdit"]
    end

    test "handles empty tools list" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "test",
        tools: []
      }

      result = Subagent.tools_to_strings(subagent)

      assert result == []
    end
  end
end
