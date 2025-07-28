# Example: Creating a subagent with plugins

alias Claude.Subagents
alias Claude.Subagents.Subagent
alias Claude.Subagents.Plugins.UsageRules

# Create a backend expert subagent with usage rules from Ecto and Phoenix
backend_expert = %Subagent{
  name: "backend_expert",
  description: "Expert in Elixir backend development with Phoenix and Ecto",
  prompt: """
  You are an expert Elixir backend developer specializing in Phoenix and Ecto.
  Focus on best practices, performance, and maintainability.
  """,
  tools: [:read, :edit, :grep, :bash],
  plugins: [
    {UsageRules, %{deps: [:phoenix, :ecto]}}
  ]
}

# Apply plugins to enhance the subagent
{:ok, enhanced_backend_expert} = Subagents.apply_plugins(backend_expert)

# The enhanced subagent now includes usage rules from Phoenix and Ecto
IO.puts("Enhanced prompt includes dependency knowledge:")
IO.puts(enhanced_backend_expert.prompt)

# Create an Ash Framework expert with multiple plugins
ash_expert = %Subagent{
  name: "ash_expert",
  description: "Expert in Ash Framework for resource-based APIs",
  prompt: "You are an expert in Ash Framework.",
  tools: [:read, :edit, :grep, :multi_edit],
  plugins: [
    {UsageRules, %{deps: [:ash, :ash_phoenix, :ash_postgres]}}
    # You could add more plugins here
  ]
}

{:ok, enhanced_ash_expert} = Subagents.apply_plugins(ash_expert)

# Example: Creating a custom plugin
defmodule ExamplePlugin do
  @behaviour Claude.Subagents.Plugin

  @impl true
  def name, do: :example

  @impl true
  def description, do: "Example custom plugin"

  @impl true
  def validate_config(%{valid: true}), do: :ok
  def validate_config(_), do: {:error, "Config must have valid: true"}

  @impl true
  def enhance(_opts) do
    enhancement = %{
      prompt_additions: "Remember to follow the project's coding standards.",
      tools: [:todo_write],
      metadata: %{source: :example}
    }

    {:ok, enhancement}
  end
end

# Use the custom plugin
custom_subagent = %Subagent{
  name: "custom_agent",
  description: "Agent with custom plugin",
  prompt: "Base prompt",
  tools: [:read],
  plugins: [
    {ExamplePlugin, %{valid: true}},
    {UsageRules, %{deps: [:tesla]}}
  ]
}

{:ok, enhanced_custom} = Subagents.apply_plugins(custom_subagent)

IO.puts("\nCustom subagent tools: #{inspect(enhanced_custom.tools)}")
# Will include both :read and :todo_write

# Example with sub-rules: Include specific documentation sections
phoenix_expert = %Subagent{
  name: "phoenix_expert",
  description: "Expert in Phoenix web development",
  prompt: "You are a Phoenix Framework expert.",
  tools: [:read, :edit, :grep, :web_fetch],
  plugins: [
    # Include main rules and specific sub-rules
    {UsageRules, %{deps: [:phoenix, "phoenix:views", "phoenix:channels"]}},
    # Or include all sub-rules from a package
    # {UsageRules, %{deps: ["phoenix:all", :phoenix_live_view]}}
  ]
}

{:ok, enhanced_phoenix} = Subagents.apply_plugins(phoenix_expert)

# Example: Load all sub-rules from a package
comprehensive_ash_expert = %Subagent{
  name: "comprehensive_ash_expert",
  description: "Comprehensive Ash Framework expert with all documentation",
  prompt: "You are an expert in all aspects of Ash Framework.",
  tools: [:read, :edit, :grep, :multi_edit, :bash],
  plugins: [
    # This will include all .md files from deps/ash/usage-rules/ folder
    {UsageRules, %{deps: ["ash:all", "ash_phoenix:all", :ash_postgres]}}
  ]
}

{:ok, enhanced_comprehensive} = Subagents.apply_plugins(comprehensive_ash_expert)