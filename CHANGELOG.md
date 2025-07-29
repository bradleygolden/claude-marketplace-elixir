# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-07-29

### Added
- **MCP Server Configuration Support**: Configure Model Context Protocol servers via `.claude.exs`
  - Automatic Tidewave configuration for Phoenix projects
  - Custom port configuration support
  - Enable/disable servers without removing configuration
  - Settings are written to `.claude/settings.json` during `mix claude.install`
- **Claude Code Sub-agent Support**: Generate custom AI agents from `.claude.exs` configuration
  - Define subagents with name, role, and instructions
  - Built-in sub-agents: meta agent, igniter specialist, claude code specialist, README manager, changelog manager, release operations manager
  - Optional usage_rules integration from dependencies
  - Markdown files are generated in `.claude/agents/` during `mix claude.install`
- **OTP Application**: Claude now starts as an OTP application (with empty supervisor)
- **Telemetry Support**: Automatic instrumentation of hook executions with telemetry events (when telemetry is available)
- **RelatedFiles Hook**: Automatically suggests related files when editing code
- **Custom Hook Registration**: Register your own hooks via `.claude.exs`
- **Typed Event Structs**: Better type safety for hook events
- Pre-commit hook now validates for unused dependencies in mix.lock
- Automatic `usage_rules` integration in the install process
- Support for `.claude.exs` configuration file
- Hook configuration support for customizing hook behavior

### Changed
- **Major Refactor**: Leveraged Igniter more extensively for better code generation
  - Simplified installation process
  - Removed CLI infrastructure in favor of direct hook scripts
  - Consolidated all installation logic into `mix claude.install`
- Hook system now uses typed event structs instead of raw maps
- Improved hook instantiation with reduced boilerplate
- Better error handling and logging throughout

### Fixed
- `claude.install` task now properly handles existing `.claude.exs` files
- Compilation checker now correctly identifies all warning types
- Hook execution is more reliable with proper error isolation

### Removed
- Removed standalone CLI commands (replaced with direct hook execution)
- Removed separate `mix claude.uninstall` task (removal is handled by `claude.install` interactive flow)

## [Unreleased]

## [0.1.0] - 2025-07-25

### Added
- Initial release

[Unreleased]: https://github.com/bradleygolden/claude/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bradleygolden/claude/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bradleygolden/claude/releases/tag/v0.1.0
