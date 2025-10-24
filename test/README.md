# Hook Testing Framework

This directory contains a simple bash-based testing framework for Claude Code plugin hooks.

## Quick Start

Run all tests:
```bash
./test/run-all-tests.sh
```

Run tests for a specific plugin:
```bash
./test/plugins/core/test-core-hooks.sh
./test/plugins/credo/test-credo-hooks.sh
```

## Architecture

### Files

- `test-hook.sh` - Base testing framework with helper functions
- `run-all-tests.sh` - Main test runner that executes all plugin tests
- `plugins/core/test-core-hooks.sh` - Tests for core plugin hooks
- `plugins/credo/test-credo-hooks.sh` - Tests for credo plugin hooks

### How It Works

The test framework simulates Claude Code's hook execution by:

1. **Constructing JSON input** - Creates the same JSON structure Claude Code sends to hooks via stdin
2. **Executing hook scripts** - Runs the hook script with the simulated input
3. **Verifying results** - Checks exit codes and output patterns match expectations

### Test Functions

#### `test_hook`

Tests a hook with exit code and output pattern verification:

```bash
test_hook \
  "Test name" \
  "path/to/hook-script.sh" \
  '{"tool_input":{"file_path":"test.ex"}}' \
  0 \  # Expected exit code
  "expected pattern in output"
```

#### `test_hook_json`

Tests a hook with JSON structure verification using jq:

```bash
test_hook_json \
  "Test name" \
  "path/to/hook-script.sh" \
  '{"tool_input":{"file_path":"test.ex"}}' \
  0 \  # Expected exit code
  'has("additionalContext")'  # jq assertion
```

## Adding New Tests

### For Existing Plugins

Add test cases to the appropriate plugin test script:

```bash
# test/plugins/your-plugin/test-your-plugin-hooks.sh

test_hook \
  "Your test description" \
  "plugins/your-plugin/scripts/your-hook.sh" \
  '{"tool_input":{...}}' \
  0 \
  "expected output"
```

### For New Plugins

1. Create test directory: `mkdir -p test/plugins/your-plugin`
2. Create test script: `test/plugins/your-plugin/test-your-plugin-hooks.sh`
3. Add source line: `source "$SCRIPT_DIR/../../test-hook.sh"`
4. Write tests using `test_hook` or `test_hook_json`
5. Add to main runner: Edit `test/run-all-tests.sh` to include your test suite
6. Make executable: `chmod +x test/plugins/your-plugin/test-your-plugin-hooks.sh`

## Example Test Script

```bash
#!/usr/bin/env bash
# Source the framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Your Plugin Hooks"
echo "================================"
echo ""

# Test 1: Hook detects issues
test_hook \
  "Hook: Detects issues in code" \
  "plugins/your-plugin/scripts/check.sh" \
  "{\"tool_input\":{\"file_path\":\"test.ex\"}}" \
  0 \
  "issue detected"

# Test 2: Hook provides JSON context
test_hook_json \
  "Hook: Provides structured output" \
  "plugins/your-plugin/scripts/check.sh" \
  "{\"tool_input\":{\"file_path\":\"test.ex\"}}" \
  0 \
  'has("additionalContext")'

print_summary
```

## CI Integration

You can run tests in CI by adding to your workflow:

```yaml
- name: Test plugin hooks
  run: ./test/run-all-tests.sh
```

## Test Coverage

Current tests cover:

### Core Plugin
- ✅ Auto-format on .ex files
- ✅ Auto-format on .exs files
- ✅ Auto-format ignores non-Elixir files
- ✅ Compile check detects errors
- ✅ Compile check ignores non-Elixir files
- ✅ Pre-commit blocks on unformatted code
- ✅ Pre-commit blocks on compilation errors
- ✅ Pre-commit ignores non-commit git commands
- ✅ Pre-commit ignores non-git commands

### Credo Plugin
- ✅ Post-edit check detects Credo violations
- ✅ Post-edit check works on .exs files
- ✅ Post-edit check ignores non-Elixir files
- ✅ Pre-commit blocks on Credo violations
- ✅ Pre-commit ignores non-commit git commands
- ✅ Pre-commit ignores non-git commands

## Debugging Failed Tests

When a test fails, the output will show:
- The test name
- Expected vs actual exit code
- The full output from the hook
- Which pattern was expected but not found

Example failure output:
```
[TEST] Auto-format hook: Formats badly formatted .ex file
  ❌ FAIL: Expected exit code 0, got 1
  Output:
    Error: mix format failed
    Could not find mix.exs
```
