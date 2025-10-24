# Core Plugin Tests

This directory contains automated tests for the core plugin hooks.

## Running Tests

### Run all core plugin tests:
```bash
./test/plugins/core/test-core-hooks.sh
```

### Run all marketplace tests (includes core + credo):
```bash
./test/run-all-tests.sh
```

### Via Claude Code slash command:
```
/qa test core
```

## Test Projects

The core plugin has three test projects with intentional issues to verify hook behavior:

### 1. autoformat-test/
- **Purpose**: Tests the auto-format hook (PostToolUse, non-blocking)
- **Contains**: Badly formatted Elixir files
- **Expected behavior**: Files automatically formatted after editing

### 2. compile-test/
- **Purpose**: Tests the compile check hook (PostToolUse, informational)
- **Contains**: Elixir code with compilation errors (`undefined_var`)
- **Expected behavior**: Compilation errors provided as context to Claude without blocking edits

### 3. precommit-test/
- **Purpose**: Tests the pre-commit validation hook (PreToolUse, blocking)
- **Contains**:
  - `lib/unformatted.ex` - Unformatted code
  - `lib/compilation_error.ex` - Compilation errors
- **Expected behavior**: Blocks git commits when validation fails

## Test Coverage

The automated test suite includes 9 tests:

**Auto-format hook**:
- ✅ Formats .ex files
- ✅ Formats .exs files
- ✅ Ignores non-Elixir files

**Compile check hook**:
- ✅ Detects compilation errors
- ✅ Ignores non-Elixir files

**Pre-commit hook**:
- ✅ Blocks on unformatted code
- ✅ Shows compilation errors
- ✅ Ignores non-commit git commands
- ✅ Ignores non-git commands

## Hook Implementation

The core plugin implements three hooks:

1. **Auto-format** (`scripts/auto-format.sh`)
   - Trigger: After Edit/Write tools on .ex/.exs files
   - Action: Runs `mix format {{file_path}}`
   - Blocking: No

2. **Compile check** (`scripts/compile-check.sh`)
   - Trigger: After Edit/Write tools on .ex/.exs files
   - Action: Runs `mix compile --warnings-as-errors`
   - Blocking: No (provides context on errors)

3. **Pre-commit validation** (`scripts/pre-commit-check.sh`)
   - Trigger: Before `git commit` commands
   - Action: Validates formatting, compilation, and unused deps
   - Blocking: Yes (exit code 2 on failures)

## Prerequisites

Before running tests, ensure the test projects have dependencies installed:
```bash
cd test/plugins/core/autoformat-test && mix deps.get
cd test/plugins/core/compile-test && mix deps.get
cd test/plugins/core/precommit-test && mix deps.get
```

The core plugin must also be installed in Claude Code:
```
/plugin marketplace add /path/to/marketplace
/plugin install core@elixir
```
