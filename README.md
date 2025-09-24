# Claude

[![Hex.pm](https://img.shields.io/hexpm/v/claude.svg)](https://hex.pm/packages/claude)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/claude/)
[![License](https://img.shields.io/hexpm/l/claude.svg)](https://github.com/bradleygolden/claude/blob/main/LICENSE)

**Help make Claude Code write production-ready Elixir, every time.**

Claude, not to be confused with _the_ Claude (probably should have picked a better name 😅), is an elixir library, batteries-included integration that helps ensure every line of code Claude writes is checked for proper formatting, compiles without warnings, and follows your project's conventions—automatically.

## 🚀 [Quickstart](documentation/guide-quickstart.md)

New to Claude? Our [quickstart guide](documentation/guide-quickstart.md) walks you through a complete setup with real examples.

## Installation

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
- Run `mix format` manually or prompt Claude to format the file
- Discover compilation errors only when you run the code or tests

## The Solution

This project hooks directly into Claude Code's workflow:

```elixir
# When Claude writes this code with formatting and compilation issues:
defmodule MyModule do
  def process_user_data(user, _options) do
    {:ok, %{id: user.id, name: user.name, email: user.email, created_at: user.created_at, updated_at: user.updated_at, status: user.status, role: user.role}} # Line too long!
  end

  def calculate_total(items) do # Unused function!
    Enum.reduce(items, 0, fn item, acc -> acc + item.price * item.quantity end)
  end
end

# Claude immediately sees:
# ⚠️ File needs formatting (line too long)
# ❌ Compilation error: unused function `calculate_total/1`
```

## Features

### 🎯 **Smart Hooks**
Automatically check formatting, catch compilation errors, validate commits, and more - with smart output handling that prevents context overflow.

- **Output Control**: Choose between `:none` mode (summary only) or `:full` mode for detailed output
- **Webhook Reporting (Experimental)**: Send hook events to external endpoints for monitoring and integration
- **Automatic Dependency Management**: Auto-install missing dependencies during hook execution

→ See [Hooks Documentation](documentation/guide-hooks.md) for details and configuration.

### 🔌 **MCP Server Support**
Integrate with Phoenix development tools via Tidewave. MCP servers are configured in `.claude.exs` and synced to `.mcp.json` when you run `mix claude.install`.

→ See [MCP Servers Guide](documentation/guide-mcp.md) for details and configuration.

### 📚 **Best Practices**

[Usage rules](https://hexdocs.pm/usage_rules) from your dependencies are automatically synced to `CLAUDE.md`, ensuring Claude follows library-specific best practices.

- **Nested Memories**: Distribute CLAUDE.md files across different directories for context-specific guidance
- **Embedded Documentation**: Usage rules are now embedded directly in CLAUDE.md for better visibility

→ See [Usage Rules Guide](documentation/guide-usage-rules.md) for how Claude integrates with usage rules.

### 🛠️ **Bundled Commands**

Pre-configured slash commands for common Elixir development tasks, automatically installed in `.claude/commands/`.

- **Library Management**: `/claude:install`, `/claude:uninstall`, `/claude:config`
- **Dependency Management**: `/mix:deps`, `/mix:deps-add`, `/mix:deps-upgrade`
- **Nested Memories**: `/memory:nested-add`, `/memory:nested-sync`, `/memory:check`

→ Type `/` in Claude Code to see all available commands.

## Installation

### Requirements
- Elixir 1.18 or later
- Claude Code CLI ([installation guide](https://docs.anthropic.com/en/docs/claude-code/quickstart))
- Mix project

### Install via Igniter

```bash
mix igniter.install claude
```

This will:
1. Add `claude` to your dependencies
2. Generate `.claude.exs` configuration file
3. Configure hooks in `.claude/settings.json`
4. Generate sub-agents in `.claude/agents/`
5. Install bundled slash commands in `.claude/commands/`
6. Sync usage rules to `CLAUDE.md`
7. Create `.mcp.json` for MCP servers (if configured)

## Configuration File

All Claude settings are managed through `.claude.exs`:

```elixir
%{
  hooks: %{
    post_tool_use: [:compile, :format],
    pre_tool_use: [:compile, :format, :unused_deps]
  },
  mcp_servers: [:tidewave],  # For Phoenix projects
  subagents: [...]            # Specialized AI assistants
}
```

Run `mix claude.install` after updating to apply changes.

## How It Works

This library leverages [Claude Code's hook system](https://docs.anthropic.com/en/docs/claude-code/hooks) to provide validation at appropriate times:

1. **Claude edits a file** → PostToolUse hook triggered immediately
2. **Hook runs Mix tasks** → `mix format`, `mix compile --warnings-as-errors`
3. **Feedback provided** → Claude sees any issues and can fix them
4. **Process repeats** → Until the code is production-ready

Additional validation runs before git commits to ensure clean code is committed. This all happens automatically, without interrupting Claude's workflow.

## Documentation

- [Quickstart Guide](documentation/guide-quickstart.md) - Get started quickly with examples
- [Hooks Reference](documentation/guide-hooks.md) - Available hooks and configuration
- [MCP Servers Guide](documentation/guide-mcp.md) - Model Context Protocol integration
- [Usage Rules Guide](documentation/guide-usage-rules.md) - Best practices integration
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

- 💬 [Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

## Roadmap

### ✅ Recently Added

**Nested Memories**
- Directory-specific CLAUDE.md files (e.g., `lib/my_app_web/CLAUDE.md` for Phoenix)
- Configure via `nested_memories` in `.claude.exs`
- Distribute context-specific usage rules across your codebase

**Bundled Slash Commands**
- `/claude:*` commands for library management (install, uninstall, config, status)
- `/elixir:*` commands for version management and compatibility checks
- `/memory:*` commands for nested memories management
- `/mix:*` commands for dependency management
- Auto-installed in `.claude/commands/` during `mix claude.install`

### 🚀 Coming Soon

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
