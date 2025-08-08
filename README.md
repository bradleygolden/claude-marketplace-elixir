# Claude

[![Hex.pm](https://img.shields.io/hexpm/v/claude.svg)](https://hex.pm/packages/claude)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/claude/)
[![License](https://img.shields.io/hexpm/l/claude.svg)](https://github.com/bradleygolden/claude/blob/main/LICENSE)

**Help make Claude Code write production-ready Elixir, every time.**

Claude, not to be confused with _the_ Claude (probably should have picked a better name 😅), is an elixir library, batteries-included integration that helps ensure every line of code Claude writes is checked for proper formatting, compiles without warnings, and follows your project's conventions—automatically.

## 🚀 [Quickstart](documentation/quickstart.md)

New to Claude? Our [quickstart guide](documentation/quickstart.md) walks you through a complete setup with real examples.

## Quick Start

```bash
# Install Claude
mix igniter.install claude

# That's it! Now Claude:
# ✓ Checks if files need formatting after editing
# ✓ Detects compilation errors immediately
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
# When Claude writes this code with formatting and compilation issues:
defmodule MyModule do
  def process_user_data(user, options) do
    {:ok, %{id: user.id, name: user.name, email: user.email, created_at: user.created_at, updated_at: user.updated_at, status: user.status, role: user.role}}
  end

  def calculate_total(items) do
    Enum.reduce(items, 0, fn item, acc -> acc + item.price * item.quantty end)  # Typo!
  end
end

# Claude immediately sees:
# ⚠️ File needs formatting (line too long)
# ❌ Compilation error: undefined function quantty/0
#
# And can fix both issues to produce:
defmodule MyModule do
  def process_user_data(user, options) do
    {:ok,
     %{
       id: user.id,
       name: user.name,
       email: user.email,
       created_at: user.created_at,
       updated_at: user.updated_at,
       status: user.status,
       role: user.role
     }}
  end

  def calculate_total(items) do
    Enum.reduce(items, 0, fn item, acc -> acc + item.price * item.quantity end)
  end
end
```

## Features

### 🎯 **Smart Hooks**
Automatically check formatting, catch compilation errors, validate commits, and more.

→ See [Hooks Documentation](documentation/hooks.md) for details and configuration.

### 🤖 **Sub-agents**
Create specialized AI assistants with built-in best practices from your dependencies.

→ See [Sub-Agents Documentation](documentation/subagents.md) for details and examples.

### 🔌 **MCP Server Support**
Integrate with Phoenix development tools via Tidewave. MCP servers are configured in `.claude.exs` and synced to `.mcp.json` when you run `mix claude.install`.

→ See [Quickstart](documentation/quickstart.md#enable-more-features) for configuration.

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
4. Create specialized sub-agents in `.claude/agents`

## Configuration

Claude uses `.claude.exs` for project-specific configuration. See our guides for:
- [Configuring Hooks](documentation/hooks.md#configuration)
- [Creating Sub-Agents](documentation/subagents.md#configuration)
- [Quickstart Examples](documentation/quickstart.md)

## How It Works

This library leverages [Claude Code's hook system](https://docs.anthropic.com/en/docs/claude-code/hooks) to intercept file operations:

1. **Claude edits a file** → PostToolUse hook triggered
2. **Hook runs Mix tasks** → `mix format --check-formatted`, `mix compile --warnings-as-errors`
3. **Feedback provided** → Claude sees any issues and can fix them
4. **Process repeats** → Until the code is production-ready

This happens automatically, without interrupting Claude's workflow.

## Documentation

- [Full Documentation](https://hexdocs.pm/claude)
- [Quickstart Guide](documentation/quickstart.md)
- [Hooks Reference](documentation/hooks.md) - Available hooks and configuration
- [Sub-Agents Reference](documentation/subagents.md) - Creating specialized AI assistants
- [Anthropic's Code Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [Anthropic's Subagents Guide](https://docs.anthropic.com/en/docs/claude-code/sub-agents)

## Contributing

We welcome contributions!

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

## Roadmap

### ✅ Recently Added

**Mix Task Generator**
- `mix claude.gen.subagent` - Interactive generator for new sub-agents with:
  - Name validation and formatting
  - Tool selection with warnings
  - Multi-line prompt support
  - Automatic `.claude.exs` integration

### 🚀 Coming Soon

**Custom Slash Commands**
- `/create-subagent` - Generate a new sub-agent with guided prompts (wraps mix task)
- Auto-generate commands in `.claude/commands/` during installation

**Scoped CLAUDE.md's**
- Directory-specific instructions (e.g., `*_web/CLAUDE.md` for Phoenix)

**More MCP Servers**
- Database tools (PostgreSQL, MySQL, Redis)
- Testing and documentation servers
- Auto-configuration based on project dependencies

**Dynamic Sub-agents**
- Generate sub-agents for each dependency with context automatically
- Common workflow templates (LiveView, GraphQL, Testing)

Want to contribute? Open an issue on [GitHub](https://github.com/bradleygolden/claude/issues)!

## License

MIT - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by the Elixir community
</p>
