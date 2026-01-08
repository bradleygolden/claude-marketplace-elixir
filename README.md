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

### Install Plugin

```bash
# Recommended: Combined plugin with all features
/plugin install elixir@elixir
```

## Available Plugins

* [elixir](./plugins/elixir/README.md) - **Recommended**: Combined plugin with all Elixir development features (auto-formatting, compilation, testing, linting, security)

### Legacy Plugins (Deprecated)

The following plugins are deprecated and will be removed in a future release. Use `elixir@elixir` instead.

* [core](./plugins/core/README.md) - Essential Elixir development support
* [ash](./plugins/ash/README.md) - Ash Framework code generation validation
* [credo](./plugins/credo/README.md) - Static code analysis
* [dialyzer](./plugins/dialyzer/README.md) - Static type analysis
* [ex_doc](./plugins/ex_doc/README.md) - Documentation quality validation
* [ex_unit](./plugins/ex_unit/README.md) - ExUnit testing automation
* [mix_audit](./plugins/mix_audit/README.md) - Dependency security audit
* [precommit](./plugins/precommit/README.md) - Phoenix 1.8+ precommit alias runner
* [sobelow](./plugins/sobelow/README.md) - Security-focused static analysis

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/bradleygolden/claude-marketplace-elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bradleygolden/claude-marketplace-elixir/discussions)

---

**Made with ❤️ for the Elixir community**
