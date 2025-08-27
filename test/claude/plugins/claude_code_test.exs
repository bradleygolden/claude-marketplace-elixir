defmodule Claude.Plugins.ClaudeCodeTest do
  use Claude.ClaudeCodeCase

  alias Claude.Plugins.ClaudeCode

  describe "claude_code_memories/0" do
    test "returns list of Claude Code documentation URLs" do
      memories = ClaudeCode.claude_code_memories()

      assert is_list(memories)
      assert length(memories) == 6

      # Check that all memories are URL tuples with proper structure
      Enum.each(memories, fn memory ->
        assert match?({:url, url, opts} when is_binary(url) and is_list(opts), memory)
        {_, url, opts} = memory

        assert String.starts_with?(url, "https://docs.anthropic.com/en/docs/claude-code/")
        assert Keyword.has_key?(opts, :as)
        assert Keyword.has_key?(opts, :cache)
        assert String.starts_with?(Keyword.get(opts, :cache), "./ai/claude_code/")
      end)
    end

    test "includes expected Claude Code documentation topics" do
      memories = ClaudeCode.claude_code_memories()
      urls = Enum.map(memories, fn {_, url, _} -> url end)

      expected_topics = [
        "hooks.md",
        "slash-commands.md",
        "sub-agents.md",
        "hooks-guide.md",
        "memory.md",
        "settings.md"
      ]

      Enum.each(expected_topics, fn topic ->
        assert Enum.any?(urls, &String.contains?(&1, topic)),
               "Expected to find URL containing '#{topic}'"
      end)
    end

    test "all cache paths point to ai/claude_code directory" do
      memories = ClaudeCode.claude_code_memories()

      Enum.each(memories, fn {_, _, opts} ->
        cache_path = Keyword.get(opts, :cache)

        assert String.starts_with?(cache_path, "./ai/claude_code/"),
               "Cache path #{cache_path} should start with ./ai/claude_code/"
      end)
    end
  end

  describe "config/1" do
    test "returns valid plugin configuration map" do
      config = ClaudeCode.config([])

      assert is_map(config)
      assert Map.has_key?(config, :nested_memories)
      assert Map.has_key?(config, :subagents)
    end

    test "ignores options since ClaudeCode has no configurable options" do
      config1 = ClaudeCode.config([])
      config2 = ClaudeCode.config(some_option: :value)

      assert config1 == config2
    end

    test "includes nested_memories with root and test directories" do
      config = ClaudeCode.config([])

      assert Map.has_key?(config.nested_memories, ".")
      assert Map.has_key?(config.nested_memories, "test")

      # Root directory should have Claude Code documentation
      root_memories = config.nested_memories["."]
      assert is_list(root_memories)
      assert length(root_memories) == 6

      # All root memories should be URL tuples
      Enum.each(root_memories, fn memory ->
        assert match?({:url, _, _}, memory)
      end)

      # Test directory should have usage rules
      test_memories = config.nested_memories["test"]
      assert "usage_rules:elixir" in test_memories
      assert "usage_rules:otp" in test_memories
    end

    test "includes Meta Agent subagent with memories" do
      config = ClaudeCode.config([])

      assert [meta_agent] = config.subagents
      assert meta_agent.name == "Meta Agent"

      assert meta_agent.description ==
               "Generates new, complete Claude Code subagent from user descriptions. Use PROACTIVELY when users ask to create new subagents. Expert agent architect."

      assert meta_agent.tools == [:write, :read, :edit, :multi_edit, :bash, :web_search]
      assert is_binary(meta_agent.prompt)
      assert String.contains?(meta_agent.prompt, "expert agent architect")

      # Meta agent should have access to Claude Code memories
      assert is_list(meta_agent.memories)
      assert length(meta_agent.memories) == 6
    end

    test "Meta Agent memories match claude_code_memories function" do
      config = ClaudeCode.config([])

      [meta_agent] = config.subagents
      expected_memories = ClaudeCode.claude_code_memories()

      assert meta_agent.memories == expected_memories
    end
  end

  describe "integration with plugin system" do
    test "can be loaded as a plugin" do
      assert {:ok, config} = Claude.Plugin.load_plugin(ClaudeCode)

      assert Map.has_key?(config, :nested_memories)
      assert Map.has_key?(config, :subagents)
    end

    test "merges correctly with other configuration" do
      plugin_configs = [ClaudeCode.config([])]
      base_config = %{nested_memories: %{"." => ["custom:memory"]}}

      final_config = Claude.Plugin.merge_configs(plugin_configs ++ [base_config])

      # Should contain both ClaudeCode memories and custom memory
      root_memories = final_config.nested_memories["."]
      assert "custom:memory" in root_memories

      # Should still have the Claude Code URL memories
      url_memories = Enum.filter(root_memories, &match?({:url, _, _}, &1))
      assert length(url_memories) == 6
    end
  end
end
