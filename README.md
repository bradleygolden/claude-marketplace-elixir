# Claude Code Plugins for Elixir

Official Claude Code plugin marketplace for Elixir and BEAM ecosystem development.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## What is this?

This is a **Claude Code plugin marketplace** that provides development tools and knowledge for Elixir, Phoenix, OTP, and the BEAM ecosystem.

Instead of being an Elixir library, this is now a pure collection of **Claude Code plugins** that anyone can use - whether you're an Elixir developer or learning Elixir.

## Quick Start

### Install the Marketplace

```bash
claude
/plugin marketplace add github:bradleygolden/claude
```

### Install Plugins

```bash
# Install base Elixir support
/plugin install elixir-core@claude
```

That's it! The plugin will automatically:
- ✅ Format Elixir files after edits
- ✅ Check compilation after edits
- ✅ Validate code before git commits

## Available Plugins

### elixir-core

Essential Elixir development support with automatic formatting and compilation checks.

**Features:**
- Auto-format `.ex` and `.exs` files with `mix format`
- Compile check with `mix compile --warnings-as-errors`
- Pre-commit validation (format check + compile + unused deps)

**Installation:**
```bash
/plugin install elixir-core@claude
```

**Learn more:** [.claude-plugin/plugins/elixir-core/README.md](.claude-plugin/plugins/elixir-core/README.md)

---

## How It Works

Claude Code plugins extend Claude's capabilities through:

- **Hooks** - Automatic checks that run during development
- **Skills** - Model-invoked knowledge (coming soon)
- **Commands** - User-invoked shortcuts (coming soon)
- **Agents** - Specialized AI assistants (coming soon)

The `elixir-core` plugin currently provides **hooks** that automatically validate your Elixir code.

## For Elixir Developers

If you're working on an Elixir project, install the `elixir-core` plugin to get:

1. **Auto-formatting** - Files are formatted automatically after edits
2. **Compile checks** - Catch compilation errors immediately
3. **Pre-commit validation** - Ensure clean code before commits

No configuration needed - just install and start coding!

## For Non-Elixir Developers

Even if you don't use Elixir, these plugins can help you:

- **Learn Elixir** - See how Elixir code should be formatted
- **Understand BEAM** - Learn OTP and Erlang VM concepts
- **Explore functional programming** - Pattern matching, immutability, etc.

Future skills will provide Elixir knowledge that Claude can use when helping you understand or write Elixir code.

## Roadmap

Future plugins planned:

- **elixir-skills** - Elixir patterns, OTP, testing knowledge
- **phoenix-skills** - Phoenix framework patterns
- **ash-skills** - Ash framework patterns
- **elixir-commands** - Quick access to common mix tasks

## Contributing

Contributions welcome! To add a plugin:

1. Create plugin directory in `.claude-plugin/plugins/`
2. Add plugin manifest in `.claude-plugin/plugin.json`
3. Add to marketplace in `.claude-plugin/marketplace.json`
4. Submit a pull request

## Documentation

- [Plugins Documentation](.claude-plugin/README.md)
- [elixir-core Plugin](.claude-plugin/plugins/elixir-core/README.md)
- [Claude Code Plugins Guide](https://docs.anthropic.com/en/docs/claude-code/plugins)
- [Claude Code Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/bradleygolden/claude/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)

---

**Made with ❤️ for the Elixir community**
