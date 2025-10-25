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
/plugin install core@elixir
/plugin install ash@elixir
/plugin install credo@elixir
/plugin install dialyzer@elixir
/plugin install ex_doc@elixir
/plugin install ex_unit@elixir
/plugin install mix_audit@elixir
/plugin install sobelow@elixir
```
## Available Plugins

* [core](./plugins/core/README.md) - Essential Elixir development support (auto-formatting, compilation checks, pre-commit validation)
* [ash](./plugins/ash/README.md) - Ash Framework code generation validation
* [credo](./plugins/credo/README.md) - Static code analysis for code quality and style
* [dialyzer](./plugins/dialyzer/README.md) - Static type analysis and discrepancy detection
* [ex_doc](./plugins/ex_doc/README.md) - Documentation quality validation
* [ex_unit](./plugins/ex_unit/README.md) - ExUnit testing automation with smart pre-commit test validation
* [mix_audit](./plugins/mix_audit/README.md) - Dependency security audit for known vulnerabilities
* [sobelow](./plugins/sobelow/README.md) - Security-focused static analysis for Phoenix applications

## License

MIT License - see [LICENSE](LICENSE) for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/bradleygolden/claude-marketplace-elixir/issues)
- **Discussions**: [GitHub Discussions](https://github.com/bradleygolden/claude-marketplace-elixir/discussions)

---

**Made with ❤️ for the Elixir community**
