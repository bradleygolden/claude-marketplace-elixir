defmodule Claude.Plugins.BaseTest do
  use Claude.ClaudeCodeCase

  alias Claude.Plugins.Base

  describe "config/1" do
    test "returns standard hooks configuration" do
      config = Base.config([])

      assert config.hooks == %{
               stop: [:compile, :format],
               subagent_stop: [:compile, :format],
               post_tool_use: [:compile, :format],
               pre_tool_use: [:compile, :format, :unused_deps]
             }
    end

    test "includes Meta Agent subagent" do
      config = Base.config([])

      assert [meta_agent] = config.subagents
      assert meta_agent.name == "Meta Agent"

      assert meta_agent.description ==
               "Generates new, complete Claude Code subagent from user descriptions. Use PROACTIVELY when users ask to create new subagents. Expert agent architect."

      assert meta_agent.tools == [:write, :read, :edit, :multi_edit, :bash, :web_search]
      assert is_binary(meta_agent.prompt)
      assert String.contains?(meta_agent.prompt, "expert agent architect")
    end

    test "ignores options since Base has no configurable options" do
      config1 = Base.config([])
      config2 = Base.config(some_option: :value)

      assert config1 == config2
    end

    test "returns valid plugin configuration map" do
      config = Base.config([])

      assert is_map(config)
      assert Map.has_key?(config, :hooks)
      assert Map.has_key?(config, :subagents)
    end
  end

  describe "integration with plugin system" do
    test "can be loaded as a plugin" do
      assert {:ok, config} = Claude.Plugin.load_plugin(Base)

      assert Map.has_key?(config, :hooks)
      assert Map.has_key?(config, :subagents)
    end

    test "merges correctly with other configuration" do
      plugin_configs = [Base.config([])]
      base_config = %{hooks: %{stop: [:custom_task]}}

      final_config = Claude.Plugin.merge_configs(plugin_configs ++ [base_config])

      assert :compile in final_config.hooks.stop
      assert :format in final_config.hooks.stop
      assert :custom_task in final_config.hooks.stop
    end
  end
end
