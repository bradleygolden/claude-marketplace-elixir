# Claude

[![Hex.pm](https://img.shields.io/hexpm/v/claude.svg)](https://hex.pm/packages/claude)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/claude/)
[![License](https://img.shields.io/hexpm/l/claude.svg)](https://github.com/bradleygolden/claude/blob/main/LICENSE)

**Help make Claude Code write production-ready Elixir, every time.**

Claude, not to be confused with _the_ Claude (probably should have picked a better name 😅), is an elixir library, batteries-included integration that helps ensure every line of code Claude writes is checked for proper formatting, compiles without warnings, and follows your project's conventions—automatically.

## 🚀 Quick Start

New to Claude? Our [quickstart guide](documentation/guide-quickstart.md) walks you through a complete setup with real examples.

```bash
# Install Claude
mix igniter.install claude

# That's it! Now Claude:
# ✓ Checks if files need formatting after editing
# ✓ Detects compilation errors immediately
# ✓ Validates code before commits
```

## Features

| Feature | Description | Learn More |
|---------|-------------|------------|
| 🎯 **Smart Hooks** | Automatic formatting, compilation checks, and code validation | [Hooks Guide](documentation/guide-hooks.md) |
| 🔌 **Plugin System** | Extensible configuration that auto-adapts to your project | [Plugin Guide](documentation/guide-plugins.md) |
| 🤖 **Sub-agents** | Specialized AI assistants with built-in best practices | [Sub-agents Guide](documentation/guide-subagents.md) |
| 📚 **Usage Rules** | Automatically syncs best practices from your dependencies | [Usage Rules Guide](documentation/guide-usage-rules.md) |
| 🔗 **MCP Servers** | Phoenix development tools integration via Tidewave | [MCP Guide](documentation/guide-mcp.md) |
| 🛠️ **Slash Commands** | Pre-configured commands for common Elixir tasks | Type `/` in Claude Code |

## Installation

**Requirements:** Elixir 1.18+, [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code/quickstart), Mix project

```bash
mix igniter.install claude
```

This sets up hooks, configuration, sub-agents, and syncs usage rules automatically.

## Configuration

All settings are managed through `.claude.exs`:

```elixir
%{
  plugins: [
    Claude.Plugins.Base,     # Standard hooks
    Claude.Plugins.Phoenix   # Auto-configured for Phoenix projects
  ]
}
```

Run `mix claude.install` after updating to apply changes.

## Documentation

- [**Quickstart Guide**](documentation/guide-quickstart.md) - Get started with examples
- [Plugin System Guide](documentation/guide-plugins.md) - Create and configure plugins
- [Hooks Reference](documentation/guide-hooks.md) - Available hooks and events
- [Sub-Agents Guide](documentation/guide-subagents.md) - Specialized AI assistants
- [MCP Servers Guide](documentation/guide-mcp.md) - Phoenix development tools
- [Usage Rules Guide](documentation/guide-usage-rules.md) - Best practices integration

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


## License

MIT - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by the Elixir community
</p>
