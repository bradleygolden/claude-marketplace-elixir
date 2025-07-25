# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir library called "Claude" that provides opinionated Claude Code integration for Elixir projects. It automatically formats code and checks for compilation errors after Claude makes edits.

## Development Commands

### Building and Dependencies
```bash
# Install dependencies
mix deps.get

# Compile the project
mix compile

# Compile with warnings as errors (used by the compilation checker hook)
mix compile --warnings-as-errors
```

### Testing
```bash
# Run all tests
mix test

# Run a specific test file
mix test test/path/to/test_file.exs

# Run tests matching a pattern
mix test --trace test/**/*_test.exs
```

### Code Quality
```bash
# Format code
mix format

# Format specific files
mix format path/to/file.ex
```

### Claude-Specific Commands
```bash
# Install Claude hooks for the current project
mix claude.install

# Uninstall Claude hooks
mix claude.uninstall

# Run a specific hook (used internally by the hook system)
mix claude hooks run <hook_identifier> <tool_name> <json_params>
```

## Architecture Overview

**Important**: For all hooks-related functionality and documentation, always reference the official Claude Code hooks documentation at https://docs.anthropic.com/en/docs/claude-code/hooks

### Core Components

1. **Hook System** (`lib/claude/hooks.ex`)
   - Central registry for all Claude Code hooks
   - Implements installation/uninstallation logic
   - Uses the `Claude.Hooks.Hook.Behaviour` behaviour for extensibility

2. **Settings Management** (`lib/claude/core/settings.ex`)
   - Handles reading/writing `.claude/settings.json`
   - Provides generic settings access for any Claude features
   - Automatically creates directory structure as needed

3. **Project Context** (`lib/claude/core/project.ex`)
   - Determines project root and Claude configuration path
   - Ensures project-scoped configuration

### Hook Implementation

All hooks implement the `Claude.Hooks.Hook.Behaviour` which requires:
- `config/0` - Returns hook configuration (type, command, matcher)
- `run/2` - Executes the hook logic
- `description/0` - Human-readable description

Current hooks:
- **ElixirFormatter** - Automatically formats .ex/.exs files after edits
- **CompilationChecker** - Checks for compilation errors after edits

### CLI Structure

The CLI is organized as Mix tasks:
- `Mix.Tasks.Claude` - Main entry point
- `Mix.Tasks.Claude.Install` - Installs hooks to `.claude/settings.json`
- `Mix.Tasks.Claude.Uninstall` - Removes hooks from settings

Internal CLI modules handle:
- `Claude.CLI` - Command routing and argument parsing
- `Claude.CLI.Hooks` - Hook-related subcommands
- `Claude.CLI.Hooks.Run` - Executes individual hooks (called by Claude Code)

### Key Design Decisions

1. **Project-scoped configuration** - All settings are stored in `.claude/settings.json` within the project directory
2. **Behaviour-based extensibility** - New hooks can be added by implementing the behaviour
3. **Fail-safe execution** - Hooks log errors but don't interrupt Claude's workflow
4. **Zero configuration** - Works out of the box with Elixir conventions
