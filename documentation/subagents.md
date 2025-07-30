# Claude Sub-Agents

Claude includes a powerful sub-agent system that lets you create specialized AI assistants for specific tasks in your project.

## Documentation

For complete documentation on Claude Code's sub-agent system:
- [Official Sub-Agents Guide](https://docs.anthropic.com/en/docs/claude-code/sub-agents) - Complete guide with examples

## What Claude Includes

When you install Claude, you automatically get:

1. **Meta Agent** - A built-in agent that helps you create new sub-agents following best practices
2. **Usage Rules Integration** - Automatic injection of library best practices into your sub-agents
3. **Project-specific configuration** - Sub-agents configured in `.claude.exs`

## Configuration

Sub-agents are configured in `.claude.exs`:

```elixir
%{
  subagents: [
    %{
      name: "test-expert",
      description: "ExUnit testing specialist",
      prompt: "You excel at writing comprehensive test suites...",
      usage_rules: ["usage_rules:elixir", "usage_rules:otp"],
      color: "green",
      model: "sonnet"
    }
  ]
}
```

### Configuration Options

- **name** (required): The human-readable name of the sub-agent
- **description** (required): When to use this sub-agent (critical for automatic delegation)
- **prompt** (required): The system prompt/instructions for the sub-agent
- **tools** (optional): List of tool atoms (e.g., `:read`, `:write`). Defaults to all tools
- **usage_rules** (optional): List of usage rules to inject
- **color** (optional): Visual color in Claude Code UI. Options: `"red"`, `"blue"`, `"green"`, `"yellow"`, `"purple"`, `"orange"`, `"pink"`, `"cyan"`
- **model** (optional): AI model to use. Options: `"sonnet"`, `"opus"`, `"haiku"`, `"inherit"`

## Creating Sub-Agents

The easiest way to create a new sub-agent is to ask Claude:

```
Create a sub-agent for handling GraphQL queries
```

The Meta Agent will automatically:
- Generate a complete sub-agent configuration
- Choose appropriate tools and permissions  
- Include relevant usage rules from your dependencies
- Add it to your `.claude.exs` file

### Manual Configuration

You can also manually add sub-agents to `.claude.exs`:

```elixir
%{
  subagents: [
    %{
      name: "database-specialist",
      description: "Database and Ecto expert for schema, queries, and migrations",
      prompt: """
      You are an expert in Ecto and database operations.
      
      When invoked, you should:
      1. Analyze the database schema
      2. Write efficient queries
      3. Handle migrations properly
      """,
      tools: [:read, :write, :edit, :bash, :grep],
      usage_rules: ["usage_rules:ecto", "usage_rules:elixir"],
      color: "blue",
      model: "inherit"
    }
  ]
}
```

## Usage Rules Integration

Sub-agents can automatically include best practices from your dependencies through usage rules:

- `usage_rules:elixir` - Elixir language best practices
- `usage_rules:otp` - OTP patterns and practices
- `usage_rules:phoenix` - Phoenix framework patterns
- `usage_rules:ecto` - Database and query best practices
- And any other dependencies that provide usage rules

## Important Notes

- **Clean Slate**: Sub-agents start fresh each time - they have no memory of previous interactions
- **Tool Inheritance**: When tools are omitted, sub-agents inherit all available tools
- **Performance**: Keep instructions focused and context minimal for best performance
- **Delegation**: The main Claude agent automatically delegates to sub-agents based on their role descriptions

For more details on sub-agent architecture, delegation patterns, and advanced usage, see the [official documentation](https://docs.anthropic.com/en/docs/claude-code/sub-agents).