# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2025-07-29

### Added
- Tidewave MCP server configuration support
- Claude Code Sub-agent support with usage rules integration
- Built-in Meta Agent included by default to help create new sub-agents
- RelatedFiles Hook to automatically suggest Claude Code to edit related files
- Support for `.claude.exs` configuration file
- Extensible hook configuration via `.claude.exs`
- Pre-commit hook now validates for unused dependencies in mix.lock
- Automatic `usage_rules` integration in the install process

See the new updated [README.md](README.md) for more details!

### Changed
- Install now requires igniter. Use `mix igniter.install claude` initially followed by
  `mix claude.install` to sync settings

### Removed
- Removed standalone CLI commands (replaced with direct hook execution)
- Removed separate `mix claude.uninstall` task to simplify things

## [0.1.0] - 2025-07-25

### Added
- Initial release

[Unreleased]: https://github.com/bradleygolden/claude/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bradleygolden/claude/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bradleygolden/claude/releases/tag/v0.1.0
