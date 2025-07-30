# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir library called "Claude" that provides batteries-included Claude Code integration for Elixir projects. It automatically formats code and checks for compilation errors after Claude makes edits.

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

# Run tests with trace for debugging
mix test --trace

# Run tests matching a pattern
mix test --trace test/**/*_test.exs

# Important: Tests use Mimic for mocking - see test/test_helper.exs
# Mock modules include: Mix.Task, System, File, IO, Claude.Hooks.Telemetry
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

# Install via Igniter
mix igniter.install claude
```

## Reference Docs

Before working with any concepts related to settings, hooks or sub agents, ALWAYS read which ever documentation is relevant to your needs below:

To reference claude code settings, please see @ai/anthropic/claude_code/configuration/setting.md
To reference claude code hooks, please see @ai/anthropic/claude_code/reference/hooks.md and @ai/anthropic/claude_code/guides/hooks.md
To reference claude code sub agents, please see @ai/anthropic/claude_code/build_with/sub_agents.md

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

### Testing Architecture

The test suite is organized with these key patterns:
- **Mimic-based mocking** - All system interactions are mocked for reliable testing
- **Test support modules** - `test/support/` contains shared testing utilities
- **Parallel structure** - Tests mirror the `lib/` structure for easy navigation
- **Mix task testing** - Special setup required using `Claude.TestHelpers.setup_mix_tasks/0`
- **Temporary directories** - Use `Claude.TestHelpers.in_tmp/1` for filesystem tests

### Sub-Agent System

The project includes several specialized sub-agents in `.claude.exs`:
- **Meta Agent** - Generates new sub-agents from user descriptions (proactive)
- **README Manager** - Maintains project documentation
- **Changelog Manager** - Handles version history using Keep a Changelog format
- **Release Operations Manager** - Coordinates release processes and validation
- **Claude Code Specialist** - Expert in Claude Code concepts using local docs

Each sub-agent is designed with:
- Clear delegation triggers (when to invoke)
- Minimal tool sets (performance optimization)
- Context discovery patterns (what to read first)
- Self-contained prompts (no memory between invocations)
- Optional visual customization (color property)
- Optional model selection (model property)

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

## Using Usage Rules

Many packages have usage rules, which you should *thoroughly* consult before taking any
action. These usage rules contain guidelines and rules *directly from the package authors*.
They are your best source of knowledge for making decisions.

## Modules & functions in the current app and dependencies

When looking for docs for modules & functions that are dependencies of the current project,
or for Elixir itself, use `mix usage_rules.docs`

```
# Search a whole module
mix usage_rules.docs Enum

# Search a specific function
mix usage_rules.docs Enum.zip

# Search a specific function & arity
mix usage_rules.docs Enum.zip/1
```


## Searching Documentation

You should also consult the documentation of any tools you are using, early and often. The best 
way to accomplish this is to use the `usage_rules.search_docs` mix task. Once you have
found what you are looking for, use the links in the search results to get more detail. For example:

```
# Search docs for all packages in the current application, including Elixir
mix usage_rules.search_docs Enum.zip

# Search docs for specific packages
mix usage_rules.search_docs Req.get -p req

# Search docs for multi-word queries
mix usage_rules.search_docs "making requests" -p req

# Search only in titles (useful for finding specific functions/modules)
mix usage_rules.search_docs "Enum.zip" --query-by title
```


<!-- usage_rules-end -->
<!-- usage_rules:elixir-start -->
## usage_rules:elixir usage
# Elixir Core Usage Rules

## Pattern Matching
- Use pattern matching over conditional logic when possible
- Prefer to match on function heads instead of using `if`/`else` or `case` in function bodies

## Error Handling
- Use `{:ok, result}` and `{:error, reason}` tuples for operations that can fail
- Avoid raising exceptions for control flow
- Use `with` for chaining operations that return `{:ok, _}` or `{:error, _}`

## Common Mistakes to Avoid
- Elixir has no `return` statement, nor early returns. The last expression in a block is always returned.
- Don't use `Enum` functions on large collections when `Stream` is more appropriate
- Avoid nested `case` statements - refactor to a single `case`, `with` or separate functions
- Don't use `String.to_atom/1` on user input (memory leak risk)
- Lists and enumerables cannot be indexed with brackets. Use pattern matching or `Enum` functions
- Prefer `Enum` functions like `Enum.reduce` over recursion
- When recursion is necessary, prefer to use pattern matching in function heads for base case detection
- Using the process dictionary is typically a sign of unidiomatic code
- Only use macros if explicitly requested
- There are many useful standard library functions, prefer to use them where possible

## Function Design
- Use guard clauses: `when is_binary(name) and byte_size(name) > 0`
- Prefer multiple function clauses over complex conditional logic
- Name functions descriptively: `calculate_total_price/2` not `calc/2`
- Predicate function names should not start with `is` and should end in a question mark. 
- Names like `is_thing` should be reserved for guards

## Data Structures
- Use structs over maps when the shape is known: `defstruct [:name, :age]`
- Prefer keyword lists for options: `[timeout: 5000, retries: 3]`
- Use maps for dynamic key-value data
- Prefer to prepend to lists `[new | list]` not `list ++ [new]`

## Mix Tasks

- Use `mix help` to list available mix tasks
- Use `mix help task_name` to get docs for an individual task
- Read the docs and options fully before using tasks

## Testing
- Run tests in a specific file with `mix test test/my_test.exs` and a specific test with the line number `mix test path/to/test.exs:123`
- Limit the number of failed tests with `mix test --max-failures n`
- Use `@tag` to tag specific tests, and `mix test --only tag` to run only those tests
- Use `assert_raise` for testing expected exceptions: `assert_raise ArgumentError, fn -> invalid_function() end`
- Use `mix help test` to for full documentation on running tests

## Debugging

- Use `dbg/1` to print values while debugging. This will display the formatted value and other relevant information in the console.

<!-- usage_rules:elixir-end -->
<!-- usage_rules:otp-start -->
## usage_rules:otp usage
# OTP Usage Rules

## GenServer Best Practices
- Keep state simple and serializable
- Handle all expected messages explicitly
- Use `handle_continue/2` for post-init work
- Implement proper cleanup in `terminate/2` when necessary

## Process Communication
- Use `GenServer.call/3` for synchronous requests expecting replies
- Use `GenServer.cast/2` for fire-and-forget messages.
- When in doubt, us `call` over `cast`, to ensure back-pressure
- Set appropriate timeouts for `call/3` operations

## Fault Tolerance
- Set up processes such that they can handle crashing and being restarted by supervisors
- Use `:max_restarts` and `:max_seconds` to prevent restart loops

## Task and Async
- Use `Task.Supervisor` for better fault tolerance
- Handle task failures with `Task.yield/2` or `Task.shutdown/2`
- Set appropriate task timeouts
- Use `Task.async_stream/3` for concurrent enumeration with back-pressure

<!-- usage_rules:otp-end -->
<!-- igniter-start -->
## igniter usage
_A code generation and project patching framework_

[igniter usage rules](deps/igniter/usage-rules.md)
<!-- igniter-end -->
<!-- usage-rules-end -->
