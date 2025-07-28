defmodule Claude.SubagentsTest do
  use ExUnit.Case, async: true
  alias Claude.Subagents
  alias Claude.Subagents.Subagent

  defmodule TestPlugin do
    @behaviour Claude.Subagents.Plugin

    @impl true
    def name, do: :test_plugin

    @impl true
    def description, do: "Test plugin for testing"

    @impl true
    def validate_config(%{valid: true}), do: :ok
    def validate_config(_), do: {:error, "Configuration must have valid: true"}

    @impl true
    def enhance(%{additional_prompt: prompt} = opts) do
      enhancement = %{
        prompt_additions: prompt,
        tools: opts[:tools] || [],
        metadata: %{test: true}
      }

      {:ok, enhancement}
    end

    def enhance(_opts) do
      enhancement = %{
        prompt_additions: "Enhanced by test plugin",
        tools: [:test_tool],
        metadata: %{test: true}
      }

      {:ok, enhancement}
    end
  end

  defmodule FailingPlugin do
    @behaviour Claude.Subagents.Plugin

    @impl true
    def name, do: :failing_plugin

    @impl true
    def description, do: "Plugin that always fails"

    @impl true
    def validate_config(_), do: {:error, "Always fails validation"}

    @impl true
    def enhance(_), do: {:error, "Always fails enhancement"}
  end

  describe "apply_plugins/1" do
    test "applies single plugin successfully" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "Base prompt",
        tools: [:read],
        plugins: [{TestPlugin, %{valid: true}}]
      }

      assert {:ok, enhanced} = Subagents.apply_plugins(subagent)
      assert enhanced.prompt =~ "Base prompt"
      assert enhanced.prompt =~ "Enhanced by test plugin"
      assert :read in enhanced.tools
      assert :test_tool in enhanced.tools
    end

    test "applies multiple plugins in order" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "Base prompt",
        tools: [:read],
        plugins: [
          {TestPlugin, %{valid: true, additional_prompt: "First enhancement"}},
          {TestPlugin, %{valid: true, additional_prompt: "Second enhancement"}}
        ]
      }

      assert {:ok, enhanced} = Subagents.apply_plugins(subagent)
      assert enhanced.prompt =~ "Base prompt"
      assert enhanced.prompt =~ "First enhancement"
      assert enhanced.prompt =~ "Second enhancement"
    end

    test "returns error when plugin validation fails" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "Base prompt",
        tools: [:read],
        plugins: [{TestPlugin, %{invalid: true}}]
      }

      assert {:error, "Configuration must have valid: true"} = Subagents.apply_plugins(subagent)
    end

    test "returns error when plugin enhancement fails" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "Base prompt",
        tools: [:read],
        plugins: [{FailingPlugin, %{}}]
      }

      assert {:error, "Always fails validation"} = Subagents.apply_plugins(subagent)
    end

    test "merges tools without duplicates" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "Base prompt",
        tools: [:read, :grep],
        plugins: [{TestPlugin, %{valid: true, tools: [:grep, :bash]}}]
      }

      assert {:ok, enhanced} = Subagents.apply_plugins(subagent)
      # TestPlugin returns :test_tool by default, not the tools from opts
      assert Enum.sort(enhanced.tools) == [:grep, :read, :test_tool]
    end

    test "handles empty plugins list" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "Base prompt",
        tools: [:read],
        plugins: []
      }

      assert {:ok, enhanced} = Subagents.apply_plugins(subagent)
      assert enhanced == subagent
    end

    test "preserves original subagent when enhancement has no additions" do
      subagent = %Subagent{
        name: "test",
        description: "test",
        prompt: "Base prompt",
        tools: [:read],
        plugins: [{TestPlugin, %{valid: true, additional_prompt: nil, tools: []}}]
      }

      assert {:ok, enhanced} = Subagents.apply_plugins(subagent)
      assert enhanced.prompt == "Base prompt"
      assert enhanced.tools == [:read]
    end
  end
end
