# Credo Plugin Tests

This directory contains automated tests for the credo plugin hooks.

## Running Tests

### Run all credo plugin tests:
```bash
./test/plugins/credo/test-credo-hooks.sh
```

### Run all marketplace tests (includes core + credo):
```bash
./test/run-all-tests.sh
```

### Via Claude Code slash command:
```
/qa test credo
```

## Test Projects

The credo plugin has two test projects with intentional Credo violations to verify hook behavior:

### 1. postedit-test/
- **Purpose**: Tests the post-edit check hook (PostToolUse, non-blocking)
- **Contains**: Elixir code with Credo violations:
  - Missing `@moduledoc`
  - Deep nesting (5+ levels)
- **Expected behavior**: Credo violations provided as context to Claude after editing

### 2. precommit-test/
- **Purpose**: Tests the pre-commit check hook (PreToolUse, blocking)
- **Contains**: Elixir code with Credo violations:
  - Missing `@moduledoc`
  - Deep nesting (5+ levels)
- **Expected behavior**: Blocks git commits when Credo violations found

## Test Coverage

The automated test suite includes 6 tests:

**Post-edit check hook**:
- ✅ Detects Credo violations
- ✅ Works on .exs files
- ✅ Ignores non-Elixir files

**Pre-commit check hook**:
- ✅ Blocks on Credo violations
- ✅ Ignores non-commit git commands
- ✅ Ignores non-git commands

## Hook Implementation

The credo plugin implements two hooks:

1. **Post-edit check** (`scripts/post-edit-check.sh`)
   - Trigger: After Edit/Write tools on .ex/.exs files
   - Action: Runs `mix credo {{file_path}}`
   - Blocking: No (provides context on violations)
   - Output: Truncated to 30 lines

2. **Pre-commit check** (`scripts/pre-commit-check.sh`)
   - Trigger: Before `git commit` commands
   - Action: Runs `mix credo --strict`
   - Blocking: Yes (exit code 2 on violations)

## Credo vs Compilation

**Credo checks CODE QUALITY** (style/readability):
- Missing moduledocs
- Function naming conventions
- Line length
- TODO/FIXME comments
- Code complexity

**NOT Credo issues** (these are compiler warnings/errors):
- Unused variables
- Undefined functions
- Type errors
- Syntax errors

## Prerequisites

Before running tests, ensure the test projects have Credo dependencies installed:
```bash
cd test/plugins/credo/postedit-test && mix deps.get
cd test/plugins/credo/precommit-test && mix deps.get
```

The credo plugin must also be installed in Claude Code:
```
/plugin marketplace add /path/to/marketplace
/plugin install credo@elixir
```
