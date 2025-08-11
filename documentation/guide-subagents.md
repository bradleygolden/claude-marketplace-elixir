# Claude Sub-Agents

Claude includes a powerful sub-agent system that lets you create specialized AI assistants for specific tasks in your project. Sub-agents provide focused expertise with their own context and can be automatically invoked based on task requirements.

> 📋 **Quick Reference**: See the [Sub-Agents Cheatsheet](../cheatsheets/subagents.cheatmd) for a concise reference of configuration options and patterns.

## Documentation

For complete documentation on Claude Code's sub-agent system:
- [Official Sub-Agents Guide](https://docs.anthropic.com/en/docs/claude-code/sub-agents) - Complete guide with examples
- [Settings Reference](https://docs.anthropic.com/en/docs/claude-code/settings) - Configuration options

## What Claude Includes

When you install Claude, you automatically get:

1. **Meta Agent** - A built-in agent that proactively helps create new sub-agents following Claude Code best practices
2. **Interactive Generator** - `mix claude.gen.subagent` command for guided sub-agent creation
3. **Usage Rules Integration** - Automatic injection of library best practices into your sub-agents
4. **Project-specific configuration** - Sub-agents configured in `.claude.exs` and auto-generated

## Configuration Format

Sub-agents are configured in `.claude.exs`:

```elixir
%{
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

**Required Fields:**
- `name` - Human-readable name (converted to kebab-case for filename)
- `description` - Clear trigger description for automatic delegation (use "MUST BE USED for...")
- `prompt` - The system prompt that defines the agent's expertise

**Optional Fields:**
- `tools` - List of tool atoms to restrict access (defaults to all tools if omitted)
- `usage_rules` - List of usage rules to include in the agent's prompt

## Creating Sub-Agents

### Method 1: Using the Meta Agent (Recommended)

The easiest way to create a new sub-agent is to simply ask Claude:

```
Create a sub-agent for handling GraphQL queries and schema validation
```

The Meta Agent will automatically:
- Generate a complete, ready-to-use sub-agent configuration
- Choose appropriate tools based on the task requirements
- Write performance-optimized prompts with context discovery patterns
- Include relevant usage rules from your dependencies
- Add the configuration to your `.claude.exs` file
- Remind you to run `mix claude.install` to generate the agent file

### Method 2: Interactive Generator

For more control, use the interactive generator:

```bash
mix claude.gen.subagent
```

This will guide you through:
- Choosing a descriptive name
- Writing a clear delegation trigger description
- Selecting specific tools (or inheriting all)
- Creating a focused system prompt
- Including relevant usage rules

The generator automatically:
- Updates your `.claude.exs` file
- Follows Claude Code best practices
- Generates the agent file in `.claude/agents/`

This provides an interactive way to create sub-agents with guided prompts.

### Method 3: Manual Configuration

You can also manually add sub-agents to `.claude.exs`:

```elixir
%{
  subagents: [
    %{
      name: "Database Expert",
      description: "MUST BE USED for Ecto migrations and database schema changes. Expert in database design.",
      prompt: """
      You are a database and Ecto expert specializing in migrations and schema design.

      ## Context Discovery
      When invoked, first check:
      - `lib/*/repo.ex` - Database configuration
      - `priv/repo/migrations/` - Existing migration patterns
      - `lib/*/schemas/` or similar - Current schema definitions

      ## Instructions
      1. Analyze existing database patterns
      2. Write efficient, safe migrations
      3. Ensure data integrity and performance
      4. Follow Ecto best practices

      ## Performance Notes
      - Limit initial context gathering
      - Use specific grep patterns
      - Focus on relevant files only
      """,
      tools: [:read, :write, :edit, :bash, :grep],
      usage_rules: [:igniter, :usage_rules_elixir] # Automatically includes package best practices
    }
  ]
}
```

**After adding manually, run:**
```bash
mix claude.install  # Generates the agent file in .claude/agents/
```

## Usage Rules Integration

Sub-agents can automatically include best practices from your project dependencies through the `usage_rules` field:

```elixir
%{
  name: "Phoenix Expert",
  description: "MUST BE USED for Phoenix controllers, views, and routing. Expert in web development.",
  prompt: "You are a Phoenix framework specialist...",
  usage_rules: [:usage_rules_elixir, :usage_rules_otp] # Automatically includes package best practices!
}
```

**Common Usage Rules:**
- `:usage_rules_elixir` - Elixir language best practices
- `:usage_rules_otp` - OTP patterns and practices
- `:igniter` - Code generation and project patching patterns
- `:phoenix` - Phoenix framework patterns (when Phoenix 1.8+ with usage rules is installed)
- Any package with usage rules in your dependencies

**Format Options:**
- `:package_name` - Loads `deps/package_name/usage-rules.md`
- `"package_name:all"` - Loads all usage rules from `deps/package_name/usage-rules/`
- `"package_name:specific_rule"` - Loads `deps/package_name/usage-rules/specific_rule.md`
- `:usage_rules_elixir` - Special case: loads `deps/usage_rules/usage-rules/elixir.md`
- `:usage_rules_otp` - Special case: loads `deps/usage_rules/usage-rules/otp.md`

## Important Design Principles

### Clean Slate Limitation
Sub-agents start with a **clean slate** on every invocation - they have no memory of previous interactions. This means:
- Context gathering operations are repeated each time
- Previous decisions or analysis must be rediscovered
- Design prompts to be self-contained and efficient

### Tool Inheritance Behavior
- **When `tools` is omitted**: Sub-agents inherit ALL tools including dynamically loaded MCP tools
- **When `tools` is specified**: The list becomes static - new MCP tools won't be available
- **No `:task` tool**: Prevents delegation loops (sub-agents cannot create other sub-agents)

### Performance Best Practices
- **Targeted Context Discovery**: Specify exactly which files to check first
- **Efficient Search Patterns**: Use specific grep patterns instead of broad searches
- **Limited Initial Reads**: Avoid reading entire directories
- **Self-Contained Prompts**: Never assume context from the main chat

## Example: Well-Designed Sub-Agent

```elixir
%{
  name: "Migration Specialist",
  description: "MUST BE USED for database migrations, schema changes, and Ecto repository operations. Expert in safe database operations.",
  prompt: """
  # Purpose
  You are a database migration specialist focusing on safe, efficient schema changes.

  ## Context Discovery (Check These First)
  Since you start fresh each time:
  1. Check `priv/repo/migrations/` for existing patterns
  2. Read the latest migration file to understand current schema
  3. Check `lib/*/repo.ex` for database configuration
  4. Look for schema files in `lib/*/schemas/` or similar

  ## Core Instructions
  1. Always create reversible migrations when possible
  2. Use appropriate indexes for performance
  3. Handle data migrations separately from schema changes
  4. Validate migration safety (no data loss)

  ## Performance Guidelines
  - Read only specific migration files, not entire directories
  - Use grep to find specific schema patterns
  - Limit context to relevant database files only
  """,
  tools: [:read, :write, :edit, :grep, :bash], # No :task to prevent delegation loops
  usage_rules: [:igniter, :usage_rules_elixir]
}
```

## Request New Sub-Agent Templates

Want a pre-built sub-agent template for common tasks? We'd love to hear your ideas!

[Request a new sub-agent template →](https://github.com/bradleygolden/claude/issues/new?title=Sub-Agent%20Template%20Request:%20[Name]&body=**Sub-Agent%20Name:**%20%0A**Use%20Case:**%20%0A**Common%20Tasks:**%20%0A%0APlease%20describe%20what%20this%20sub-agent%20would%20do%20and%20why%20it%20would%20be%20useful%20for%20Elixir%20developers.)

Popular requests might be added as default templates or examples!

## Troubleshooting

**Sub-agents not appearing in Claude?**
- Check `.claude/agents/` directory exists with agent files
- Verify `.claude.exs` has subagent definitions
- Run `mix claude.install` to regenerate agent files
- Restart your Claude Code session

**Sub-agent not working as expected?**
- Remember: sub-agents have no memory between invocations
- Ensure the prompt is self-contained with all needed context
- Check tool restrictions - agent might need additional tools
- Verify usage rules are correctly specified

**Generator issues?**
- Use `mix claude.gen.subagent` for interactive mode
- Provide all flags for non-interactive: `--name`, `--description`, `--prompt`
- Tool names should be in snake_case when entering

**Meta Agent not creating agents?**
- Ensure Meta Agent has write permissions (`:write` tool)
- Check `.claude.exs` after Meta Agent runs
- Run `mix claude.install` to activate new agents

**Need help?**
- 💬 [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

## Learn More

For more details on sub-agent architecture, delegation patterns, and advanced usage, see the [official documentation](https://docs.anthropic.com/en/docs/claude-code/sub-agents).
