# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- @reference system with URL caching for documentation references in nested memories
- Plugin system for extending .claude.exs configuration with reusable modules
- Register all hook events when reporters are configured for complete observability

### Fixed
- Webhook reporters now correctly receive hook events during execution
- Stop hooks with all non-blocking failures now exit with code 0 to prevent infinite loops in CI

## [0.5.1] - 2025-08-22

### Changed
- Stop and subagent_stop hooks now use `blocking?: false` by default to prevent infinite loops
- When compilation or formatting fails in stop hooks, they now provide informational feedback without blocking Claude
- This prevents situations where Claude gets stuck trying to fix issues repeatedly

### Why This Change
Stop hooks with blocking errors (exit code 2) could cause Claude to loop infinitely when trying to fix compilation errors. The new defaults keep users informed while preventing loops. Users can still override with `blocking?: true` if needed, but should be aware of the loop risk.

## [0.5.0] - 2025-08-19

### Changed

**BREAKING CHANGE**: Root CLAUDE.md now uses reference links to usage rules instead of inlining content

- Previously was a little overzealous pulling in all context into CLAUDE.md which resulted in this error: ⚠ Large CLAUDE.md will impact performance (...k chars > 40.0k)
- Root CLAUDE.md now contains links to usage rules in `deps/` instead of inlining full content
- Nested memory CLAUDE.md files continue to inline usage rules for focused context-specific guidance
- Existing projects will get the optimized format on next `mix claude.install`

## [0.4.0] - 2025-08-18

### Added
- New `:output` option for hooks to control output verbosity (defaults to `:none`)
- Nested memories support for distributing CLAUDE.md files across different directories (#98)
- Webhook reporter (experimental) for hook events with configurable HTTP endpoints (#97)
- Bundled slash commands for common Elixir development tasks (#101)
- GitHub Actions CI workflow for automated testing across Elixir/OTP versions (#95)
- Hook wrapper system for improved dependency management during hook execution
- Auto-installation of dependencies when `auto_install_deps?` is configured (`false` by default)

### Changed
- Usage rules documentation now embedded directly in CLAUDE.md for better LLM context (#96)

### Fixed
- Fixed "Error during compaction" issue caused by long hook outputs exceeding context window (#93)
- Fixed startup issues when dependencies are missing (#99)

## [0.3.4] - 2025-08-12

### Fixed
- Meta agent now properly generates lowercase-hyphen subagent names and auto-installs them

## [0.3.3] - 2025-08-11

### Fixed
- Fixed confusing upgrade message loop where `mix claude.install` would tell users to run `mix claude.upgrade`, which didn't actually fix the issue
- `mix claude.install` now provides clear manual upgrade instructions when detecting outdated hooks format
- `mix claude.upgrade` converted to a diagnostic tool that shows manual upgrade instructions instead of attempting auto-upgrade

## [0.3.2] - 2025-08-11

### Fixed
- Hopefully fixed upgrader including for versions 0.3.0 and 0.3.1 (where the upgrader was broken)

## [0.3.1] - 2025-08-11

### Fixed
- Fixed `mix claude.upgrade` generating invalid `.claude.exs` syntax when migrating custom hooks from v0.2.x

## [0.3.0] - 2025-08-11

**TLDR:** any mix task can be a hook now!

This release focuses on enhancing the hook system and improving the user experience. If you're using a previous version, please run `mix claude.install`.

### Added
- Automatic Tidewave installation for Phoenix projects - `mix claude.install` now automatically installs and configures Tidewave when Phoenix is detected
- Support for more hooks events
- New atom-based hook system with shortcuts (`:compile`, `:format`, `:unused_deps`)
- New cheatsheets for common patterns

### Changed
- **BREAKING** Hooks now use a single dispatcher system (`mix claude.hooks.run`) in `.claude/settings.json`
- **BREAKING** Hook configuration has been completely overhauled, see the [hooks guide](documentation/guide-hooks.md)
- **BREAKING** Temporarily dropped support for the related files hook to get this release out. I plan to add it back soon!
- Improved `mix claude.install` output
- Improved the meta-agent system prompt to better use usage rules

### Removed
- Removed telemetry modules (unused)

## [0.2.4] - 2025-08-01

### Fixed
- Output MCP server configuration to correct `.mcp.json` location instead of `.claude/settings.json`
- Fixed a bug where hooks weren't configured properly which prevented them from being useful to claude claude code. Please run `mix claude.install` to sync the new settings and pull in the fix

## [0.2.3] - 2025-07-30

### Changed

- Updated `claude.install` task to use `--inline usage_rules:all` argument when syncing usage rules, ensuring sub-rules from the usage_rules package are inlined directly into CLAUDE.md

## [0.2.2] - 2025-07-29

### Fixed

- Updated usage rules and included sub rules in the hex package

## [0.2.1] - 2025-07-29

### Fixed
- Hook scripts now properly include `igniter` as a dependency, fixing compilation errors when hooks are executed

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
- **BREAKING**: Installation now requires Igniter. Use `mix igniter.install claude` initially followed by
  `mix claude.install` to sync settings
- **BREAKING**: Hook execution paths have changed. Users upgrading from v0.1.0 should:
  1. Delete the old Claude hooks from `.claude/settings.json`
  2. Run `mix igniter.install claude` to reinstall with the new structure

### Removed
- Removed standalone CLI commands (replaced with direct hook execution)
- Removed separate `mix claude.uninstall` task to simplify things

## [0.1.0] - 2025-07-25

### Added
- Initial release

[Unreleased]: https://github.com/bradleygolden/claude/compare/v0.5.0...HEAD
[0.5.0]: https://github.com/bradleygolden/claude/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/bradleygolden/claude/compare/v0.3.4...v0.4.0
[0.3.4]: https://github.com/bradleygolden/claude/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/bradleygolden/claude/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/bradleygolden/claude/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/bradleygolden/claude/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/bradleygolden/claude/compare/v0.2.4...v0.3.0
[0.2.4]: https://github.com/bradleygolden/claude/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/bradleygolden/claude/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/bradleygolden/claude/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/bradleygolden/claude/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/bradleygolden/claude/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bradleygolden/claude/releases/tag/v0.1.0
