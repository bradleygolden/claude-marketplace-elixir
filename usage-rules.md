# Claude Usage Rules

Claude is an Elixir library that provides batteries-included Claude Code integration for Elixir projects. It automatically formats code, checks for compilation errors after Claude makes edits, and provides generators and tooling for deeply integrating Claude Code into your project.

## What's New in v0.3.0

- **Mix Task Generator**: `mix claude.gen.subagent` for creating sub-agents
- **Atom-based Hooks**: Simple atom shortcuts that expand to full configurations
- **Single Dispatcher System**: Efficient hook execution via `mix claude.hooks.run`

## Installation

Claude only supports Igniter installation:

```bash
mix igniter.install claude
```

## Core Commands

### Installation
```bash
# Install Claude hooks and sync configuration
mix claude.install
```

### Generator
```bash
# Generate a new sub-agent interactively
mix claude.gen.subagent
```

## Hook System

Claude provides an atom-based hook system with sensible defaults. Hooks are configured in `.claude.exs` using atom shortcuts that expand to full configurations.

### Hook Events

Claude supports all Claude Code hook events:

- **`pre_tool_use`** - Before tool execution (can block tools)
- **`post_tool_use`** - After tool execution completes successfully
- **`user_prompt_submit`** - Before processing user prompts (can add context or block)
- **`notification`** - When Claude needs permission or input is idle
- **`stop`** - When Claude Code finishes responding (main agent)
- **`subagent_stop`** - When a sub-agent finishes responding
- **`pre_compact`** - Before context compaction (manual or automatic)
- **`session_start`** - When Claude Code starts or resumes a session

### Available Hook Atoms

- `:compile` - Runs `mix compile --warnings-as-errors` with `halt_pipeline?: true`
- `:format` - Runs `mix format --check-formatted` (checks only, doesn't auto-format)
- `:unused_deps` - Runs `mix deps.unlock --check-unused` (pre_tool_use on git commits only)

### Default Hook Configuration

The default `.claude.exs` includes these hooks:

```elixir
%{
  hooks: %{
    stop: [:compile, :format],
    subagent_stop: [:compile, :format], 
    post_tool_use: [:compile, :format],
    # These only run on git commit commands
    pre_tool_use: [:compile, :format, :unused_deps]
  }
}
```

### Custom Hook Configuration

You can use explicit configurations with options:

```elixir
%{
  hooks: %{
    post_tool_use: [
      :format,
      {"custom_check", when: [:write, :edit], halt_pipeline?: true},
      {"cmd ./lint.sh", blocking?: false}  # Shell command with "cmd " prefix
    ]
  }
}
```

**Available Options:**
- `:when` - Tool/event matcher (atoms, strings, or lists)
- `:command` - Command pattern for Bash tools (string or regex)
- `:halt_pipeline?` - Stop subsequent hooks on failure (default: false)
- `:blocking?` - Convert non-zero exit to code 2 (default: true)
- `:env` - Environment variables map

### Hook Documentation

For complete documentation about Claude Code's hook system, see:

  * https://docs.anthropic.com/en/docs/claude-code/hooks
  * https://docs.anthropic.com/en/docs/claude-code/hooks-guide

Claude provides several built-in hooks for common Elixir development tasks. See the
[Hooks Documentation](documentation/hooks.md) for available hooks and configuration options.

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

## Sub-agents (v0.3.0+)

Claude supports creating specialized AI assistants (sub-agents) for your project with built-in best practices.

### Interactive Generation

Use the new generator to create sub-agents:

```bash
mix claude.gen.subagent
```

This will prompt you for:
- Name and description
- Tool permissions 
- System prompt
- Usage rules integration

### Built-in Meta Agent

Claude includes a Meta Agent by default that helps you create new sub-agents proactively. The Meta Agent:
- Generates complete sub-agent configurations from descriptions
- Chooses appropriate tools and permissions
- Follows Claude Code best practices for performance and context management
- Uses WebSearch to reference official Claude Code documentation

**Usage**: Just ask Claude to "create a new sub-agent for X" and it will automatically generate the configuration.

### Manual Configuration

You can also configure sub-agents manually in `.claude.exs`:

```elixir
%{
  subagents: [
    %{
      name: "Database Expert", 
      description: "MUST BE USED for Ecto migrations and database schema changes. Expert in database design.",
      prompt: """
      You are a database and Ecto expert specializing in migrations and schema design.
      
      Always check existing migration files and schemas before making changes.
      Follow Ecto best practices for data integrity and performance.
      """,
      tools: [:read, :write, :edit, :grep, :bash],
      usage_rules: [:ash, :ash_postgres]  # Automatically includes package best practices!
    }
  ]
}
```

**Usage Rules Integration**: Sub-agents can automatically include usage rules from your dependencies, ensuring they follow library-specific best practices.

## Settings Management

Claude uses `.claude.exs` to configure specific settings for your project that are then ported to
the `.claude` directory for use by Claude Code.

### Complete `.claude.exs` configuration example:

```elixir
# .claude.exs - Claude configuration for this project
%{
  # Hook configuration using atom shortcuts
  hooks: %{
    stop: [:compile, :format],
    subagent_stop: [:compile, :format],
    post_tool_use: [:compile, :format],
    # Only run on git commit commands
    pre_tool_use: [:compile, :format, :unused_deps]
  },

  # MCP servers configuration
  mcp_servers: [
    # For Phoenix projects
    {:tidewave, [port: 4000]}
  ],

  # Specialized sub-agents
  subagents: [
    %{
      name: "Test Expert",
      description: "MUST BE USED for ExUnit testing and test file generation. Expert in test patterns.",
      prompt: """
      You are an ExUnit testing expert specializing in comprehensive test suites.
      
      Always check existing test patterns and follow project conventions.
      Focus on testing behavior, edge cases, and integration scenarios.
      """,
      tools: [:read, :write, :edit, :grep, :bash],
      usage_rules: [:usage_rules_elixir, :usage_rules_otp]
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
