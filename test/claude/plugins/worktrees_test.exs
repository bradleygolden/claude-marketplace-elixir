defmodule Claude.Plugins.WorktreesTest do
  use Claude.ClaudeCodeCase

  alias Claude.Plugins.Worktrees

  describe "config/1" do
    test "enables auto_install_deps" do
      config = Worktrees.config([])

      assert config.auto_install_deps? == true
    end

    test "ignores options since Worktrees has no configurable options" do
      config1 = Worktrees.config([])
      config2 = Worktrees.config(some_option: :value)

      assert config1 == config2
    end

    test "returns valid plugin configuration map" do
      config = Worktrees.config([])

      assert is_map(config)
      assert Map.has_key?(config, :auto_install_deps?)
    end
  end

  describe "integration with plugin system" do
    test "can be loaded as a plugin" do
      assert {:ok, config} = Claude.Plugin.load_plugin(Worktrees)

      assert Map.has_key?(config, :auto_install_deps?)
    end

    test "merges correctly with other configuration" do
      plugin_configs = [Worktrees.config([])]
      base_config = %{some_other_setting: :value}

      final_config = Claude.Plugin.merge_configs(plugin_configs ++ [base_config])

      assert final_config.auto_install_deps? == true
      assert final_config.some_other_setting == :value
    end

    test "works with Base plugin" do
      base_config = Claude.Plugins.Base.config([])
      worktrees_config = Worktrees.config([])

      final_config = Claude.Plugin.merge_configs([base_config, worktrees_config])

      assert Map.has_key?(final_config, :hooks)
      assert Map.has_key?(final_config, :subagents)
      assert final_config.auto_install_deps? == true
    end
  end
end
