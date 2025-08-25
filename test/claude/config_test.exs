defmodule Claude.ConfigTest do
  use Claude.ClaudeCodeCase

  describe "read_base_config/0" do
    test "reads valid .claude.exs file", %{test_dir: test_dir} do
      config_content = """
      %{
        hooks: %{stop: [:compile]},
        test_value: :from_file
      }
      """

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, config} = Claude.Config.read_base_config()
        assert %{hooks: %{stop: [:compile]}, test_value: :from_file} = config
      end)
    end

    test "returns error when file doesn't exist", %{test_dir: test_dir} do
      File.cd!(test_dir, fn ->
        assert {:error, ".claude.exs not found"} = Claude.Config.read_base_config()
      end)
    end

    test "returns error when file contains invalid Elixir", %{test_dir: test_dir} do
      Claude.Test.create_file(test_dir, ".claude.exs", "invalid syntax %{")

      File.cd!(test_dir, fn ->
        assert {:error, message} = Claude.Config.read_base_config()
        assert message =~ "TokenMissingError"
      end)
    end

    test "returns error when file doesn't return a map", %{test_dir: test_dir} do
      Claude.Test.create_file(test_dir, ".claude.exs", "\"not a map\"")

      File.cd!(test_dir, fn ->
        assert {:error, message} = Claude.Config.read_base_config()
        assert message =~ "must return a map"
        assert message =~ "\"not a map\""
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

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Claude.Config.read()
        assert result.hooks == %{stop: [:compile]}
        assert result.test_value == :base
      end)
    end

    test "returns base config when plugins is empty list", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [],
        hooks: %{stop: [:compile]}
      }
      """

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Claude.Config.read()
        assert result == %{hooks: %{stop: [:compile]}}
        refute Map.has_key?(result, :plugins)
      end)
    end
  end

  describe "read/0 with plugins" do
    test "loads and merges plugins successfully", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Simple, TestPlugins.Hooks],
        hooks: %{stop: [:custom_task]},
        local_value: :override
      }
      """

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Claude.Config.read()

        refute Map.has_key?(result, :plugins)

        assert :compile in result.hooks.stop
        assert :format in result.hooks.stop
        assert :custom_task in result.hooks.stop
        assert result.hooks.post_tool_use == [:compile]
        assert result.hooks.pre_tool_use == [:unused_deps]

        assert result.local_value == :override

        assert result.test_value == :simple
      end)
    end

    test "handles plugin with options", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [{TestPlugins.WithOptions, mode: :strict}],
        additional: :value
      }
      """

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Claude.Config.read()

        assert result.mode == :strict
        assert result.hooks.stop == [:compile, :format, :test]
        assert result.additional == :value
        refute Map.has_key?(result, :plugins)
      end)
    end

    test "returns error when plugin fails to load", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: [TestPlugins.Simple, NonExistentPlugin],
        hooks: %{stop: [:compile]}
      }
      """

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:error, message} = Claude.Config.read()
        assert message =~ "Failed to load plugins"
        assert message =~ "NonExistentPlugin not found"
      end)
    end

    test "returns error when plugins is not a list", %{test_dir: test_dir} do
      config_content = """
      %{
        plugins: :not_a_list,
        hooks: %{stop: [:compile]}
      }
      """

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:error, message} = Claude.Config.read()
        assert message =~ "plugins must be a list"
      end)
    end
  end

  describe "integration tests" do
    test "complex configuration merging", %{test_dir: test_dir} do
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

      Claude.Test.create_file(test_dir, ".claude.exs", config_content)

      File.cd!(test_dir, fn ->
        assert {:ok, result} = Claude.Config.read()

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

      Claude.Test.create_file(test_dir, ".claude.exs", legacy_config_content)

      File.cd!(test_dir, fn ->
        {expected_config, _} = Code.eval_string(legacy_config_content)
        assert {:ok, result} = Claude.Config.read()
        assert result == expected_config
      end)
    end
  end
end
