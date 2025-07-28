defmodule Claude.Core.ClaudeExsTest do
  use ExUnit.Case, async: true

  alias Claude.Core.ClaudeExs
  alias Claude.Subagents.Subagent

  setup do
    # Create a temporary directory for test files
    tmp_dir = System.tmp_dir!()
    test_dir = Path.join(tmp_dir, "claude_exs_test_#{:rand.uniform(10000)}")
    File.mkdir_p!(test_dir)

    on_exit(fn ->
      File.rm_rf!(test_dir)
    end)

    {:ok, test_dir: test_dir}
  end

  describe "load_from_path/1" do
    test "loads valid configuration", %{test_dir: test_dir} do
      path = Path.join(test_dir, ".claude.exs")

      File.write!(path, """
      %{
        hooks: [MyHook],
        subagents: [
          %{
            name: "Test Agent",
            description: "A test agent",
            prompt: "You are a test agent"
          }
        ]
      }
      """)

      assert {:ok, config} = ClaudeExs.load_from_path(path)
      assert config.hooks == [MyHook]
      assert [subagent] = config.subagents
      assert subagent.name == "Test Agent"
    end

    test "returns error for non-existent file", %{test_dir: test_dir} do
      path = Path.join(test_dir, "nonexistent.exs")
      assert {:error, :not_found} = ClaudeExs.load_from_path(path)
    end

    test "returns error for invalid Elixir syntax", %{test_dir: test_dir} do
      path = Path.join(test_dir, ".claude.exs")
      File.write!(path, "%{invalid syntax")

      assert {:error, {:eval_error, message}} = ClaudeExs.load_from_path(path)
      assert is_binary(message)
    end

    test "returns error for non-map configuration", %{test_dir: test_dir} do
      path = Path.join(test_dir, ".claude.exs")
      File.write!(path, "[]")

      assert {:error, "Configuration must be a map"} = ClaudeExs.load_from_path(path)
    end

    test "returns error for invalid configuration keys", %{test_dir: test_dir} do
      path = Path.join(test_dir, ".claude.exs")
      File.write!(path, "%{invalid_key: true}")

      assert {:error, message} = ClaudeExs.load_from_path(path)
      assert String.contains?(message, "Invalid configuration keys")
    end
  end

  describe "get_subagents/1" do
    test "returns empty list when no subagents configured" do
      config = %{}
      assert [] = ClaudeExs.get_subagents(config)
    end

    test "returns subagents when configured" do
      config = %{
        subagents: [
          %{name: "Agent 1", description: "First", prompt: "Test"},
          %{name: "Agent 2", description: "Second", prompt: "Test"}
        ]
      }

      subagents = ClaudeExs.get_subagents(config)
      assert length(subagents) == 2
      assert Enum.at(subagents, 0).name == "Agent 1"
      assert Enum.at(subagents, 1).name == "Agent 2"
    end
  end

  describe "subagent_from_config/1" do
    test "creates subagent from valid config" do
      config = %{
        name: "Test Agent",
        description: "A test agent",
        prompt: "You are a test agent",
        tools: [:read, :write],
        usage_rules: ["ecto", "phoenix"]
      }

      assert {:ok, %Subagent{} = subagent} = ClaudeExs.subagent_from_config(config)
      assert subagent.name == "Test Agent"
      assert subagent.description == "A test agent"
      assert subagent.prompt == "You are a test agent"
      assert subagent.tools == [:read, :write]

      # Check that usage_rules creates a plugin
      assert [{plugin_module, opts}] = subagent.plugins
      assert plugin_module == Claude.Subagents.Plugins.UsageRules
      assert opts.deps == ["ecto", "phoenix"]
    end

    test "creates subagent without optional fields" do
      config = %{
        name: "Minimal Agent",
        description: "Minimal",
        prompt: "Test"
      }

      assert {:ok, %Subagent{} = subagent} = ClaudeExs.subagent_from_config(config)
      assert subagent.name == "Minimal Agent"
      assert subagent.tools == []
      assert subagent.plugins == []
    end

    test "returns error for missing required fields" do
      config = %{name: "Test", description: "Test"}

      assert {:error, message} = ClaudeExs.subagent_from_config(config)
      assert String.contains?(message, "Missing required keys")
      assert String.contains?(message, "prompt")
    end

    test "returns error for invalid name" do
      config = %{
        name: "",
        description: "Test",
        prompt: "Test"
      }

      assert {:error, "Name must be a non-empty string"} = ClaudeExs.subagent_from_config(config)
    end

    test "returns error for invalid tools" do
      config = %{
        name: "Test",
        description: "Test",
        prompt: "Test",
        # Should be atoms
        tools: ["read", "write"]
      }

      assert {:error, "Tools must be a list of atoms"} = ClaudeExs.subagent_from_config(config)
    end

    test "returns error for invalid usage_rules" do
      config = %{
        name: "Test",
        description: "Test",
        prompt: "Test",
        # Should be strings
        usage_rules: [:ecto, :phoenix]
      }

      assert {:error, "Usage rules must be a list of strings"} =
               ClaudeExs.subagent_from_config(config)
    end
  end

  describe "validation" do
    test "validates subagents must be a list", %{test_dir: test_dir} do
      path = Path.join(test_dir, ".claude.exs")
      File.write!(path, "%{subagents: %{}}")

      assert {:error, "Subagents must be a list"} = ClaudeExs.load_from_path(path)
    end

    test "validates each subagent configuration", %{test_dir: test_dir} do
      path = Path.join(test_dir, ".claude.exs")

      File.write!(path, """
      %{
        subagents: [
          %{name: "Valid", description: "Valid", prompt: "Valid"},
          %{name: "Invalid"}  # Missing required fields
        ]
      }
      """)

      assert {:error, message} = ClaudeExs.load_from_path(path)
      assert String.contains?(message, "Missing required keys")
    end
  end
end
