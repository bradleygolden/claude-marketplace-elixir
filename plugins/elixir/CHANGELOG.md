# Changelog

All notable changes to this plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2025-01-11

### Added
- Hex audit check for retired dependencies (`mix hex.audit`)
  - Post-edit: Runs when editing mix.exs, provides immediate feedback
  - Pre-commit: Runs as first check (before format/compile), blocks on retired deps
  - No external dependency required (built into Hex)

## [1.1.0] - 2025-01-10

### Added
- hex-docs-search and usage-rules skills now available as slash commands

## [1.0.0] - 2025-01-08

### Changed
- Simplified skill documentation for faster LLM processing
- Added model override (haiku) and context forking to skills

### Fixed
- Sobelow security check now correctly parses multiline JSON output

## [1.0.0-rc.1] - 2025-01-08

### Added
- Combined plugin consolidating all Elixir development tools into one
- Automatic code formatting on file edit
- Compilation checking with warnings-as-errors
- Credo static analysis (when dependency present)
- Ash Framework codegen validation (when dependency present)
- Dialyzer type checking (when dependency present)
- ExDoc documentation validation (when dependency present)
- ExUnit test runner with --stale flag (when test/ exists)
- Mix Audit security scanning (when dependency present)
- Sobelow security analysis (when dependency present)
- Automatic deferral to `mix precommit` alias if present
- Cross-process locking for ExDoc to prevent race conditions
- hex-docs-search skill for Hex package documentation
- usage-rules skill for package best practices

### Notes
- This plugin replaces the individual plugins (core, credo, ash, dialyzer, ex_doc, ex_unit, mix_audit, precommit, sobelow)
- All checks are automatically enabled/disabled based on project dependencies
- No configuration required - just install and code
