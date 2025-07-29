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
# Run claude.install again and choose to remove hooks when prompted

# Hooks are executed automatically by Claude Code via the scripts in .claude/hooks/

# MCP Server Management
# MCP servers are configured directly in .claude.exs - see below

# MCP server configuration in .claude.exs supports:
# - Simple atom format: :tidewave
# - Custom port: {:tidewave, [port: 5000]}
# - Disable without removing: {:tidewave, [port: 4000, enabled?: false]}
```

## Reference Docs

Before working with any concepts related to settings, hooks or sub agents, ALWAYS read which ever documentation is relevant to your needs below:

To reference claude code settings, please see @docs/anthropic/claude_code/configuration/settings.md
To reference claude code hooks, please see @docs/anthropic/claude_code/reference/hooks.md and @docs/anthropic/claude_code/guides/hooks.md
To reference claude code sub agents, please see @docs/anthropic/claude_code/build_with/sub_agents.md

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

4. **MCP Server System** (`lib/claude/mcp/`)
   - **Catalog** - Tidewave configuration for Phoenix projects
   - **Registry** - Reads mcp_servers from `.claude.exs` (supports both atom and tuple formats)
   - **Installer** - Syncs MCP configuration to settings.json
   - **Automatic** - Tidewave is auto-configured for Phoenix projects
   - **Custom Config** - Supports port customization: `{:tidewave, [port: 5000]}`
   - **Enable/Disable** - Servers can be disabled with `enabled?: false` option

### Hook Implementation

All hooks implement the `Claude.Hooks.Hook.Behaviour` which requires:
- `config/0` - Returns hook configuration (type, command, matcher)
- `run/2` - Executes the hook logic
- `description/0` - Human-readable description

Current hooks:
- **ElixirFormatter** - Automatically formats .ex/.exs files after edits
- **CompilationChecker** - Checks for compilation errors after edits
- **PreCommitCheck** - Validates formatting, compilation, and unused dependencies before commits

### CLI Structure

The system is organized as:
- `Mix.Tasks.Claude.Install` - Installs hooks and generates scripts

Hook execution is handled via direct script invocation:
- Scripts are generated in `.claude/hooks/` directory
- Each hook runs via `mix run` for proper project context
- No CLI infrastructure needed - hooks execute directly

### Key Design Decisions

1. **Project-scoped configuration** - All settings are stored in `.claude/settings.json` within the project directory
2. **Behaviour-based extensibility** - New hooks can be added by implementing the behaviour
3. **Fail-safe execution** - Hooks log errors but don't interrupt Claude's workflow
4. **Zero configuration** - Works out of the box with Elixir conventions

<!-- usage-rules-start -->
<!-- usage-rules-header -->
# Usage Rules

**IMPORTANT**: Consult these usage rules early and often when working with the packages listed below.
Before attempting to use any of these packages or to discover if you should use them, review their
usage rules to understand the correct patterns, conventions, and best practices.
<!-- usage-rules-header-end -->

<!-- usage_rules-start -->
## usage_rules usage
_A dev tool for Elixir projects to gather LLM usage rules from dependencies_

[usage_rules usage rules](deps/usage_rules/usage-rules.md)
<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
[usage_rules:elixir usage rules](deps/usage_rules/usage-rules/elixir.md)
<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
[usage_rules:otp usage rules](deps/usage_rules/usage-rules/otp.md)
<!-- usage_rules:otp-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- usage-rules-end -->
