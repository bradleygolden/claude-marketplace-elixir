# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Project changelog with version history
- Documentation integration for Hex and ex_doc

## [0.1.0] - 2025-07-25

### Added
- Initial release of Claude Code integration for Elixir projects
- Automatic code formatting via ElixirFormatter hook
- Compilation error checking via CompilationChecker hook
- Project-wide hook sharing support (#22)
- Support for Claude settings across worktrees
- Igniter integration for easier installation (#16, #19, #20)
- Usage rules documentation support (#17)
- Pre-commit hook for blocking on errors (#14)
- Project documentation (CLAUDE.md) (#13)
- Mix tasks for managing Claude hooks:
  - `mix claude.install` - Install hooks for the current project
  - `mix claude.uninstall` - Remove hooks from project
  - `mix claude hooks run` - Execute individual hooks (internal use)
- Settings management in `.claude/settings.json`
- Zero-configuration approach with Elixir conventions
- Comprehensive test coverage
- Documentation with ex_doc
- Behaviour-based extensibility for custom hooks

### Changed
- Formatter hook to use check-only mode (#12)
- Installation instructions for development-only usage (#10)

### Fixed
- Claude hooks installation issues (#11)

[Unreleased]: https://github.com/bradleygolden/claude/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bradleygolden/claude/releases/tag/v0.1.0