# Claude

[![Hex.pm](https://img.shields.io/hexpm/v/claude.svg)](https://hex.pm/packages/claude)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/claude/)
[![License](https://img.shields.io/hexpm/l/claude.svg)](https://github.com/bradleygolden/claude/blob/main/LICENSE)

**Make Claude Code write production-ready Elixir, every time.**

Claude is a batteries-included integration that ensures every line of code Claude writes is properly formatted, compiles without warnings, and follows your project's conventions—automatically.

## Quick Start

```bash
# Install Claude
mix igniter.install claude

# That's it! Claude now automatically:
# ✓ Formats every file after editing
# ✓ Checks for compilation errors
# ✓ Validates code before commits
```

## The Problem

When Claude Code writes Elixir, you often need to:
- Run `mix format` manually after every edit
- Discover compilation errors only when you run the code
- Remember to update related test files
- Ensure consistent code style across your team

## The Solution

Claude hooks directly into Claude Code's workflow:

```elixir
# Before Claude: Unformatted code that might not compile
defmodule  MyModule  do
  def hello(  name  )  do
    "Hello, #{ nam }!"  # Oops, typo!
  end
end

# After Claude: Production-ready code, automatically
defmodule MyModule do
  def hello(name) do
    "Hello, #{name}!"
  end
end
```

## Features

### 🎯 **Smart Hooks**
- **Format on save** - Every `.ex` and `.exs` file is automatically formatted
- **Compile checks** - Catch errors immediately, not in production
- **Pre-commit validation** - Block bad commits before they happen
- **Related files** - "You edited the schema, want to check the Phoenix Context?"

### 🔧 **Extensible**
```elixir
# .claude.exs - Add your own hooks
%{
  hooks: [
    MyApp.Hooks.SecurityScanner,
    MyApp.Hooks.TestRunner
  ]
}
```

### 🤖 **Sub-agents**
Create specialized AI assistants for your project with built-in best practices:

```elixir
%{
  subagents: [
    %{
      name: "genserver-agent",
      role: "Genserver agent",
      instructions: "You are an writing and testing genservers...",
      usage_rules: ["usage_rules:elixir", "usage_rules:otp"]  # Automatically includes best practices!
    }
  ]
}
```

**Built-in Meta Agent:** Claude includes a Meta Agent by default that helps you create new sub-agents following best practices. Just ask: "Create a sub-agent for handling GraphQL queries" and the Meta Agent will:
- Generate a complete sub-agent configuration
- Choose appropriate tools and permissions  
- Include relevant usage rules from your dependencies
- Add it to your `.claude.exs` file

**Usage Rules Integration:** The real power comes from [usage rules](https://hexdocs.pm/usage_rules/readme.html) - documentation from your dependencies that gets automatically injected into sub-agents, ensuring they follow library best practices.

### 🔌 **MCP Server Support**
Integrate with Phoenix development tools via Tidewave:
```elixir
%{
  mcp_servers: [tidewave: [port: 4000]]  # Automatic Phoenix integration
}
```

Tidewave will be added automatically if you're using Phoenix in your project.

### 📚 **Best Practices**

[Usage rules](https://hexdocs.pm/usage_rules/readme.html) will be added to your `CLAUDE.md` automatically so you can have the best chance of your agents following best practices.

## Installation

### Requirements
- Elixir ~> 1.18
- Claude Code (CLI)
- Mix with Igniter support

### Install via Igniter

```bash
mix igniter.install claude
```

This will:
1. Add `claude` to your dependencies
2. Generate `.claude.exs` configuration
3. Install hooks in `.claude/settings.json` and `.claude/hooks`
4. Create specialized sub-agents in `.claud/agents`

## Configuration

Claude uses `.claude.exs` for project-specific configuration:

```elixir
# .claude.exs
%{
  # Hooks to run (built-in + custom)
  hooks: [
    # Optional: Enable related files suggestions
    Claude.Hooks.PostToolUse.RelatedFiles,

    # Add your custom hooks
    MyApp.Hooks.CredoChecker
  ],

  # MCP servers (for Phoenix projects, only tidewave is supported, use claude manually to add other mcp servers)
  mcp_servers: [
    # Simple configuration
    :tidewave,

    # Or with options
    {:tidewave, [port: 5000]}
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

## Built-in Sub-agents

Claude includes a Meta Agent by default to help you create new sub-agents.

### Meta Agent
The Meta Agent is your sub-agent architect. It helps you create new, well-designed sub-agents by:
- Analyzing your requirements and suggesting optimal configuration
- Choosing appropriate tools and permissions
- Integrating usage rules from your dependencies
- Following Claude Code best practices for performance and context management

**Usage:** Just ask Claude to create a new sub-agent, and the Meta Agent will automatically help.

### Common Sub-agent Patterns
- **Test Specialist** - Focused on writing and maintaining tests
- **Documentation Manager** - Keeps docs in sync with code
- **Database Expert** - Specializes in Ecto queries and migrations
- **API Designer** - Creates consistent REST/GraphQL APIs
- **Performance Optimizer** - Identifies and fixes bottlenecks

## Creating Custom Hooks

Extend Claude with your own hooks:

```elixir
defmodule MyApp.Hooks.CredoChecker do
  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:edit, :write],
    description: "Runs Credo on modified files"

  @impl true
  def run(json_input) do
    # Your hook logic here
    :ok
  end
end
```

## How It Works

This library leverages [Claude Code's hook system](https://docs.anthropic.com/en/docs/claude-code/hooks) to intercept file operations:

1. **Claude edits a file** → PostToolUse hook triggered
2. **Hook runs Mix tasks** → `mix format`, `mix compile --warnings-as-errors`
3. **Feedback provided** → Claude sees any issues and can fix them
4. **Process repeats** → Until the code is production-ready

This happens automatically, without interrupting Claude's workflow.

## Documentation

- [Full Documentation](https://hexdocs.pm/claude)
- [Claude Code Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks)
- TODO: Claude subagents guide

## Contributing

We welcome contributions! See our [contributing guide](CONTRIBUTING.md) for details.

```bash
# Run tests
mix test

# Format code
mix format

# Run quality checks
mix compile --warnings-as-errors
```

## Support

- 📖 [Documentation](https://hexdocs.pm/claude)
- 💬 [Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

## License

MIT - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by the Elixir community
</p>
