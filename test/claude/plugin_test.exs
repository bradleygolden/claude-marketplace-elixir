defmodule Claude.PluginTest do
  use Claude.ClaudeCodeCase

  describe "load_plugin/1" do
    test "loads a simple plugin module" do
      assert {:ok, config} = Claude.Plugin.load_plugin(TestPlugins.Simple)
      assert %{hooks: %{stop: [:compile]}, test_value: :simple} = config
    end

    test "loads plugin with options" do
      assert {:ok, config} = Claude.Plugin.load_plugin({TestPlugins.WithOptions, mode: :strict})
      assert %{mode: :strict, hooks: %{stop: [:compile, :format, :test]}} = config
    end

    test "loads plugin with default options" do
      assert {:ok, config} = Claude.Plugin.load_plugin(TestPlugins.WithOptions)
      assert %{mode: :default, hooks: %{stop: [:compile, :format]}} = config
    end

    test "returns error for non-existent module" do
      assert {:error, message} = Claude.Plugin.load_plugin(NonExistentPlugin)
      assert message =~ "Plugin module NonExistentPlugin not found"
    end

    test "returns error for module without behaviour" do
      assert {:error, message} = Claude.Plugin.load_plugin(TestPlugins.Invalid)
      assert message =~ "does not implement Claude.Plugin behaviour"
    end

    test "returns error for failing plugin" do
      assert {:error, message} = Claude.Plugin.load_plugin(TestPlugins.Failing)
      assert message =~ "failed to load"
      assert message =~ "Intentional failure"
    end

    test "handles tuple format with module and options" do
      assert {:ok, config} =
               Claude.Plugin.load_plugin({TestPlugins.WithOptions, [mode: :minimal]})

      assert %{mode: :minimal, hooks: %{stop: [:compile]}} = config
    end
  end

  describe "load_plugins/1" do
    test "loads multiple plugins successfully" do
      plugins = [TestPlugins.Simple, {TestPlugins.WithOptions, mode: :strict}]
      assert {:ok, configs} = Claude.Plugin.load_plugins(plugins)
      assert length(configs) == 2

      [simple_config, options_config] = configs
      assert %{test_value: :simple} = simple_config
      assert %{mode: :strict} = options_config
    end

    test "returns errors for failed plugins" do
      plugins = [TestPlugins.Simple, NonExistentPlugin]
      assert {:error, errors} = Claude.Plugin.load_plugins(plugins)
      assert length(errors) == 1
      assert hd(errors) =~ "NonExistentPlugin not found"
    end

    test "returns empty list for no plugins" do
      assert {:ok, []} = Claude.Plugin.load_plugins([])
    end
  end

  describe "merge_configs/1" do
    test "handles empty list" do
      assert %{} = Claude.Plugin.merge_configs([])
    end

    test "handles single config" do
      config = %{hooks: %{stop: [:compile]}}
      assert ^config = Claude.Plugin.merge_configs([config])
    end

    test "merges simple maps - later values win" do
      configs = [
        %{a: 1, b: 2},
        %{b: 3, c: 4}
      ]

      result = Claude.Plugin.merge_configs(configs)
      assert result.a == 1
      assert result.b == 3
      assert result.c == 4
    end

    test "deep merges nested maps" do
      configs = [
        %{hooks: %{stop: [:compile]}},
        %{hooks: %{stop: [:format], post_tool_use: [:compile]}}
      ]

      result = Claude.Plugin.merge_configs(configs)
      assert :compile in result.hooks.stop
      assert :format in result.hooks.stop
      assert result.hooks.post_tool_use == [:compile]
    end

    test "concatenates and deduplicates simple lists" do
      configs = [
        %{tools: [:read, :write]},
        %{tools: [:write, :edit, :read]}
      ]

      result = Claude.Plugin.merge_configs(configs)
      assert :read in result.tools
      assert :write in result.tools
      assert :edit in result.tools
      assert length(result.tools) == 3
    end

    test "merges lists of maps by name" do
      configs = [
        %{
          subagents: [
            %{name: "test-runner", tools: [:bash]},
            %{name: "code-reviewer", tools: [:read]}
          ]
        },
        %{
          subagents: [
            %{name: "test-runner", description: "Runs tests"},
            %{name: "debugger", tools: [:edit]}
          ]
        }
      ]

      result = Claude.Plugin.merge_configs(configs)
      subagents = result.subagents

      assert length(subagents) == 3

      test_runner = Enum.find(subagents, &(&1.name == "test-runner"))
      assert %{name: "test-runner", tools: [:bash], description: "Runs tests"} = test_runner
    end

    test "handles complex nested structures" do
      configs = [
        %{
          hooks: %{stop: [:compile]},
          nested: %{
            deep: %{
              values: [:a, :b]
            }
          }
        },
        %{
          hooks: %{stop: [:format], post_tool_use: [:compile]},
          nested: %{
            deep: %{
              values: [:b, :c],
              other: :value
            },
            shallow: :data
          }
        }
      ]

      result = Claude.Plugin.merge_configs(configs)

      assert :compile in result.hooks.stop
      assert :format in result.hooks.stop
      assert result.hooks.post_tool_use == [:compile]

      assert result.nested.shallow == :data
      assert result.nested.deep.other == :value
      assert :a in result.nested.deep.values
      assert :b in result.nested.deep.values
      assert :c in result.nested.deep.values
    end

    test "handles mixed types gracefully" do
      configs = [
        %{value: [:list]},
        %{value: :atom}
      ]

      result = Claude.Plugin.merge_configs(configs)
      assert result.value == :atom
    end
  end

  describe "integration with real plugin types" do
    test "merges hooks plugins correctly" do
      configs = [
        TestPlugins.Simple,
        TestPlugins.Hooks
      ]

      assert {:ok, plugin_configs} = Claude.Plugin.load_plugins(configs)
      result = Claude.Plugin.merge_configs(plugin_configs)

      assert :compile in result.hooks.stop
      assert :format in result.hooks.stop
      assert result.hooks.post_tool_use == [:compile]
      assert result.hooks.pre_tool_use == [:unused_deps]
    end

    test "merges subagents correctly" do
      configs = [
        TestPlugins.Subagents,
        TestPlugins.Complex
      ]

      assert {:ok, plugin_configs} = Claude.Plugin.load_plugins(configs)
      result = Claude.Plugin.merge_configs(plugin_configs)

      assert length(result.subagents) == 3
      agent_names = Enum.map(result.subagents, & &1.name)
      assert "test-runner" in agent_names
      assert "code-reviewer" in agent_names
      assert "complex-agent" in agent_names
    end
  end
end
