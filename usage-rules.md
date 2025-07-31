# Claude Usage Rules

Claude (not to be confused with Claude/Claude Code) is an Elixir library that provides batteries-included Claude Code integration for Elixir projects. It automatically formats code, checks for compilation errors after Claude makes edits, and includes tooling for deeply integrating Claude Code into your project using Elixir.

## Installation

Claude only supports igniter installation:

```bash
mix igniter.install claude
```

## Core Commands

### Installation
```bash
# Install Claude hooks for the current project
mix claude.install
```

## Hook System

Claude provides a behavior-based hook system that integrates with Claude Code. All hooks implement `Claude.Hooks.Hook.Behaviour`.

### Built-in Hooks

1. **ElixirFormatter** - Checks if Elixir files need formatting after Claude edits them (PostToolUse hook for Write, Edit, MultiEdit)
2. **CompilationChecker** - Checks for compilation errors after Claude edits Elixir files (PostToolUse hook for Write, Edit, MultiEdit)
3. **PreCommitCheck** - Validates formatting, compilation, and unused dependencies before allowing git commits (PreToolUse hook for Bash)

### Optional Hooks

1. **RelatedFiles** - Suggests updating related files based on naming patterns after edits (PostToolUse hook for Write, Edit, MultiEdit)

#### RelatedFiles Hook Examples

The RelatedFiles hook helps you keep related files in sync by suggesting updates when you modify code. Here are some examples:

**Basic Usage** - Enable with default patterns:

```elixir
# .claude.exs
%{
  hooks: [
    # This will use the default lib <-> test mappings
    Claude.Hooks.PostToolUse.RelatedFiles
  ]
}
```

**Custom Patterns** - Configure your own file relationships:

```elixir
# .claude.exs
%{
  hooks: [
    {Claude.Hooks.PostToolUse.RelatedFiles, %{
      patterns: [
        # When editing Phoenix controllers, suggest updating views
        {"lib/*_web/controllers/*_controller.ex", "lib/*_web/controllers/*_html.ex"},

        # When editing LiveView modules, suggest updating tests
        {"lib/*_web/live/*_live.ex", "test/*_web/live/*_live_test.exs"},

        # When editing schemas, suggest updating migrations
        {"lib/*/schemas/*.ex", "priv/repo/migrations/*_*.exs"},

        # Bidirectional mapping for documentation
        {"lib/**/*.ex", "docs/**/*.md"},
        {"docs/**/*.md", "lib/**/*.ex"}
      ]
    }}
  ]
}
```

The hook uses glob patterns (`*` matches any characters except `/`, `**` matches any characters including `/`) and will suggest Claude to review related files after you make edits.

### Creating Custom Hooks

The easiest way to create a hook is using the `use` macro:

```elixir
defmodule MyProject.MyHook do
  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:edit, :write],
    description: "My custom hook that runs after edits"

  @impl Claude.Hooks.Hook.Behaviour
  def run(json_input) when is_binary(json_input) do
    # Your hook logic here
    :ok
  end
end
```

#### Options for `use` macro:

- `:event` - Hook event type (default: `:post_tool_use`)
  - `:pre_tool_use`
  - `:post_tool_use`
  - `:user_prompt_submit`
  - `:notification`
  - `:stop`
  - `:subagent_stop`
- `:matcher` - Tool matcher pattern (default: `:*`)
  - Can be a single atom: `:edit`, `:write`, `:bash`
  - Can be a list: `[:edit, :write, :multi_edit]`
  - Can be `:*` to match all tools
- `:description` - Human-readable description

For more documentation about hooks see official documentation below:

  * https://docs.anthropic.com/en/docs/claude-code/hooks
  * https://docs.anthropic.com/en/docs/claude-code/hooks-guide

ALWAYS consult the official documentation before implementing custom hooks.

#### Manual Implementation

If you need more control, you can implement the behaviour manually:

```elixir
defmodule MyProject.MyHook do
  @behaviour Claude.Hooks.Hook.Behaviour

  @impl true
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "# Hook command configured by ScriptInstaller"
    }
  end

  @impl true
  def run(json_input) when is_binary(json_input) do
    # Your hook logic here
    :ok
  end

  @impl true
  def description do
    "My custom hook description"
  end

  defp identifier do
    __MODULE__
    |> Module.split()
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end
end
```

## MCP Server Support

Claude supports Model Context Protocol (MCP) servers, currently with built-in support for Tidewave (Phoenix development tools).

### Configuring MCP Servers

MCP servers are configured in `.claude.exs` and automatically synced to `.mcp.json`:

```elixir
%{
  mcp_servers: [
    # Simple atom format (uses default port 4000)
    :tidewave,

    # Custom port configuration
    {:tidewave, [port: 5000]},

    # Disable without removing
    {:tidewave, [port: 4000, enabled?: false]}
  ]
}
```

When you run `mix claude.install`, this configuration is automatically written to `.mcp.json` in the correct format for Claude Code to recognize. The `.mcp.json` file follows the [official MCP configuration format](https://docs.anthropic.com/en/docs/claude-code/mcp).

**Note**: While only Tidewave is officially supported through the installer, you can manually add other MCP servers to `.mcp.json` following the Claude Code documentation.

## Sub-agents

Claude supports creating specialized AI assistants (sub-agents) for your project with built-in best practices.

### Built-in Meta Agent

Claude includes a Meta Agent by default that helps you create new sub-agents following best practices. The Meta Agent:
- Analyzes your requirements and suggests optimal configuration
- Chooses appropriate tools and permissions
- Integrates usage rules from your dependencies
- Follows Claude Code best practices for performance and context management

**Usage**: Just ask Claude to create a new sub-agent, and the Meta Agent will automatically help.

### Creating Sub-agents

Configure sub-agents in `.claude.exs`:

```elixir
%{
  subagents: [
    %{
      name: "genserver-agent",
      role: "GenServer specialist",
      instructions: "You excel at writing and testing GenServers...",
      usage_rules: ["usage_rules:elixir", "usage_rules:otp"]  # Automatically includes best practices!
    }
  ]
}
```

**Usage Rules Integration**: Sub-agents can automatically include usage rules from your dependencies, ensuring they follow library best practices.

## Settings Management

Claude uses `.claude.exs` to configure specific settings for your project that are then ported to
the `.claude` directory for use by Claude Code.

### Complete `.claude.exs` configuration example:

```elixir
# .claude.exs - Claude configuration for this project
%{
  # Register hooks (built-in + custom)
  hooks: [
    # Optional: Enable related files suggestions
    Claude.Hooks.PostToolUse.RelatedFiles,

    # Add your custom hooks
    MyProject.Hooks.CustomFormatter,
    MyProject.Hooks.SecurityChecker
  ],

  # MCP servers configuration
  mcp_servers: [
    # For Phoenix projects
    {:tidewave, [port: 4000]}
  ],

  # Specialized sub-agents
  subagents: [
    %{
      name: "test_expert",
      role: "ExUnit testing specialist",
      instructions: "You excel at writing comprehensive test suites...",
      usage_rules: ["usage_rules:elixir", "usage_rules:otp"]
    }
  ]
}
```

## Reference Documentation

For official Claude Code documentation:

 * Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
 * Hooks Guide: https://docs.anthropic.com/en/docs/claude-code/hooks-guide
 * Settings: https://docs.anthropic.com/en/docs/claude-code/settings
 * Sub-agents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
