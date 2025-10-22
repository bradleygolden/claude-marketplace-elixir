defmodule Claude.ConfigTest do
  use Claude.ClaudeCodeCase

  alias Claude.Config

  describe "read_base_config/1" do
    test "reads valid .claude.exs file", %{test_dir: test_dir} do
      config_content = """
      %{
        hooks: %{stop: [:compile]},
        test_value: :from_file
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, config} = Config.read_base_config()
        assert config.hooks.stop == [:compile]
        assert config.test_value == :from_file
      end)
    end

    test "returns error when file doesn't exist", %{test_dir: test_dir} do
      File.cd!(test_dir, fn ->
        assert {:error, ".claude.exs not found"} = Config.read_base_config()
      end)
    end

    test "returns error when file contains invalid Elixir syntax", %{test_dir: test_dir} do
      create_config_file(test_dir, "invalid syntax %{")

      File.cd!(test_dir, fn ->
        assert {:error, message} = Config.read_base_config()
        assert message =~ "TokenMissingError"
      end)
    end

    test "returns error when file doesn't return a map", %{test_dir: test_dir} do
      create_config_file(test_dir, "\"not a map\"")

      File.cd!(test_dir, fn ->
        assert {:error, message} = Config.read_base_config()
        assert message =~ "must return a map"
        assert message =~ "\"not a map\""
      end)
    end

    test "handles complex nested configuration", %{test_dir: test_dir} do
      config_content = """
      %{
        hooks: %{
          stop: [:compile, :format],
          post_tool_use: [:lint]
        },
        nested: %{
          deep: %{
            value: [:item1, :item2]
          }
        },
        mcp_servers: [:server1, :server2]
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, config} = Config.read_base_config()
        assert config.hooks.stop == [:compile, :format]
        assert config.hooks.post_tool_use == [:lint]
        assert config.nested.deep.value == [:item1, :item2]
        assert config.mcp_servers == [:server1, :server2]
      end)
    end
  end

  describe "read/0 without plugins" do
    test "returns base config when no plugins specified", %{test_dir: test_dir} do
      config_content = """
      %{
        hooks: %{stop: [:compile]},
        test_value: :base
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()
        assert result.hooks.stop == [:compile]
        assert result.test_value == :base
        refute Map.has_key?(result, :plugins)
      end)
    end

    test "returns base config when plugins is empty list", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [],
        hooks: %{stop: [:compile]}
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()
        assert result.hooks.stop == [:compile]
        refute Map.has_key?(result, :plugins)
      end)
    end

    test "preserves all configuration keys without plugins", %{test_dir: test_dir} do
      config_content = """
      %{
        hooks: %{stop: [:compile]},
        mcp_servers: [:tidewave],
        auto_install_deps?: true,
        nested_memories: %{"." => ["usage_rules:elixir"]},
        custom_field: :custom_value
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()
        assert result.hooks.stop == [:compile]
        assert result.mcp_servers == [:tidewave]
        assert result.auto_install_deps? == true
        assert result.nested_memories["."] == ["usage_rules:elixir"]
        assert result.custom_field == :custom_value
      end)
    end
  end

  describe "read/0 with plugins" do
    test "loads and merges single plugin successfully", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Simple],
        hooks: %{stop: [:custom_task]},
        local_value: :override
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        refute Map.has_key?(result, :plugins)

        assert :compile in result.hooks.stop
        assert :custom_task in result.hooks.stop
        assert result.test_value == :simple
        assert result.local_value == :override
      end)
    end

    test "loads and merges multiple plugins successfully", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Simple, TestPlugins.Hooks],
        hooks: %{stop: [:custom_task]},
        local_value: :override
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        refute Map.has_key?(result, :plugins)

        assert :compile in result.hooks.stop
        assert :format in result.hooks.stop
        assert :custom_task in result.hooks.stop
        assert result.hooks.post_tool_use == [:compile]
        assert result.hooks.pre_tool_use == [:unused_deps]
        assert result.test_value == :simple
        assert result.local_value == :override
      end)
    end

    test "handles plugin with options", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [{TestPlugins.WithOptions, mode: :strict}],
        additional: :value
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert result.mode == :strict
        assert result.hooks.stop == [:compile, :format, :test]
        assert result.additional == :value
        refute Map.has_key?(result, :plugins)
      end)
    end

    test "handles complex plugin configuration merging", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Complex, TestPlugins.Subagents],
        hooks: %{
          stop: [:final_task],
          user_defined: [:my_task]
        },
        mcp_servers: [:additional_server],
        auto_install_deps?: false,
        nested_value: %{
          inner: %{
            deep: [:value3],
            new_key: :added
          },
          top_level: :new
        }
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert length(result.subagents) == 3
        agent_names = Enum.map(result.subagents, & &1.name)
        assert "test-runner" in agent_names
        assert "code-reviewer" in agent_names
        assert "complex-agent" in agent_names

        assert :compile in result.hooks.stop
        assert :format in result.hooks.stop
        assert :final_task in result.hooks.stop
        assert result.hooks.post_tool_use == [:format]
        assert result.hooks.user_defined == [:my_task]

        assert result.mcp_servers == [:tidewave, :additional_server]
        assert result.auto_install_deps? == false

        assert :value1 in result.nested_value.inner.deep
        assert :value2 in result.nested_value.inner.deep
        assert :value3 in result.nested_value.inner.deep
        assert result.nested_value.inner.new_key == :added
        assert result.nested_value.top_level == :new

        refute Map.has_key?(result, :plugins)
      end)
    end

    test "plugin configuration takes precedence over base in merging order", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Simple],
        test_value: :base_value,
        hooks: %{stop: [:base_task]}
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert result.test_value == :base_value
        assert :compile in result.hooks.stop
        assert :base_task in result.hooks.stop
      end)
    end
  end

  describe "read/0 error handling" do
    test "returns error when plugin fails to load", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Simple, NonExistentPlugin],
        hooks: %{stop: [:compile]}
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:error, message} = Config.read()
        assert message =~ "Failed to load plugins"
        assert message =~ "NonExistentPlugin not found"
      end)
    end

    test "returns error when plugin raises exception", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Failing],
        hooks: %{stop: [:compile]}
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:error, message} = Config.read()
        assert message =~ "Failed to load plugins"
        assert message =~ "Intentional failure for testing"
      end)
    end

    test "returns error when plugins is not a list", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: :not_a_list,
        hooks: %{stop: [:compile]}
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:error, message} = Config.read()
        assert message =~ "plugins must be a list"
        assert message =~ ":not_a_list"
      end)
    end

    test "returns error when plugins contains invalid entries", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Simple, "invalid_plugin"],
        hooks: %{stop: [:compile]}
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert_raise FunctionClauseError, fn ->
          Config.read()
        end
      end)
    end
  end

  describe "real-world plugin integration" do
    test "works with actual Claude plugins", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [Claude.Plugins.Base]
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert result.hooks.post_tool_use == [:compile, :format]
        assert result.hooks.pre_tool_use == [:compile, :format, :unused_deps]
        refute Map.has_key?(result, :plugins)
      end)
    end
  end

  describe "configuration features" do
    test "handles nested memories configuration", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.WithMemories],
        nested_memories: %{
          "custom" => ["additional:rule"]
        }
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert is_map(result.nested_memories)

        root_memories = result.nested_memories["."]

        assert {:url, "https://example.com/api-docs.md",
                as: "API Documentation", cache: "./ai/api/docs.md"} in root_memories

        assert "usage_rules:elixir" in root_memories
        assert "custom:memory" in root_memories

        test_memories = result.nested_memories["test"]
        assert "usage_rules:otp" in test_memories

        assert {:url, "https://example.com/test-guide.md",
                as: "Test Guide", cache: "./ai/test/guide.md"} in test_memories

        assert result.nested_memories["custom"] == ["additional:rule"]
      end)
    end

    test "handles reporters configuration", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.WithReporters],
        reporters: [
          {:jsonl, path: "./logs"}
        ]
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert is_list(result.reporters)
        assert {:webhook, url: "https://example.com/plugin-webhook"} in result.reporters
        assert {:jsonl, path: "./logs"} in result.reporters
      end)
    end

    test "handles subagents with memories", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.WithSubagentMemories]
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert length(result.subagents) == 1
        agent = hd(result.subagents)
        assert agent.name == "memory-test-agent"
        assert is_list(agent.memories)
        assert "usage_rules:elixir" in agent.memories

        assert {:url, "https://example.com/agent-docs.md",
                as: "Agent Docs", cache: "./ai/agent/docs.md"} in agent.memories
      end)
    end
  end

  describe "backward compatibility" do
    test "works exactly like before when no plugins specified", %{test_dir: test_dir} do
      legacy_config_content = """
      %{
        hooks: %{
          stop: [:compile, :format],
          subagent_stop: [:compile, :format],
          post_tool_use: [:compile, :format],
          pre_tool_use: [:compile, :format, :unused_deps]
        },
        auto_install_deps?: true,
        subagents: [
          %{
            name: "Meta Agent",
            description: "Generates new subagents",
            prompt: "You are an expert agent architect...",
            tools: [:write, :read, :edit, :multi_edit, :bash, :web_search]
          }
        ],
        nested_memories: %{
          "." => [
            {:url, "https://example.com", as: "Example", cache: "./cache.md"}
          ]
        }
      }
      """

      create_config_file(test_dir, legacy_config_content)

      File.cd!(test_dir, fn ->
        {expected_config, _} = Code.eval_string(legacy_config_content)
        assert {:ok, result} = Config.read()
        assert result == expected_config
      end)
    end

    test "preserves exact structure of legacy configurations", %{test_dir: test_dir} do
      config_content = """
      %{
        custom_key: :custom_value,
        deeply: %{
          nested: %{
            structure: [1, 2, 3],
            with_atoms: [:a, :b, :c]
          }
        },
        mixed_list: [:atom, "string", 123],
        boolean_flag: false
      }
      """

      create_config_file(test_dir, config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Config.read()

        assert result.custom_key == :custom_value
        assert result.deeply.nested.structure == [1, 2, 3]
        assert result.deeply.nested.with_atoms == [:a, :b, :c]
        assert result.mixed_list == [:atom, "string", 123]
        assert result.boolean_flag == false
      end)
    end
  end

  defp create_config_file(base_dir, content) do
    config_path = Path.join(base_dir, ".claude.exs")
    File.write!(config_path, content)
    config_path
  end
end
