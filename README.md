> [!NOTE]
> This repository has changed significantly and may look quite different from before.
> With the release of Claude Plugins, the previous implementation is now mostly irrelevant.
> This new version adapts the earlier approach to align with the latest plugin architecture and conventions.
> If you're looking for the previous version, please visit see version [v0.5.3](https://github.com/bradleygolden/claude/releases/tag/v0.5.3).

# Claude Code Plugins for Elixir

Unofficial Claude Code plugin marketplace for Elixir and BEAM ecosystem development.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## What is this?

This is a [**Claude Code plugin marketplace**](https://docs.claude.com/en/docs/claude-code/plugin-marketplaces) that provides Elixir and BEAM ecosystem development tools for Claude Code.

## Quick Start

### Install the Marketplace

```bash
claude
/plugin marketplace add bradleygolden/claude-marketplace-elixir
```

### Install Plugins

```bash
/plugin install ash@elixir
/plugin install core@elixir
/plugin install credo@elixir
/plugin install dialyzer@elixir
/plugin install sobelow@elixir
```
## Available Plugins

* [ash](./plugins/ash/README.md) - Ash Framework code generation validation
* [core](./plugins/core/README.md) - Universal Elixir development support for any Elixir project
* [credo](./plugins/credo/README.md) - Credo static code analysis
* [dialyzer](./plugins/dialyzer/README.md) - Dialyzer static type analysis
* [sobelow](./plugins/sobelow/README.md) - Sobelow security-focused static analysis for Phoenix applications

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/bradleygolden/claude-marketplace-elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bradleygolden/claude-marketplace-elixir/discussions)

---

**Made with ❤️ for the Elixir community**
