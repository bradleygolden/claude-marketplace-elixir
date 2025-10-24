---
description: Test marketplace plugin(s) with intelligent failure analysis
argument-hint: "[plugin-name] (optional - omit to test all)"
allowed-tools: Bash, Write, Read
---

# Marketplace Plugin Test Runner

This command runs the automated plugin test suite using the bash-based testing framework.

## Examples

```bash
# Run all plugin tests
/test-marketplace

# Run tests for a specific plugin
/test-marketplace core
/test-marketplace credo
```

## Execute Tests

Use TodoWrite to track progress through these steps:

```
⏳ Determine test scope (all plugins vs specific plugin)
⏳ Run test scripts and capture output
⏳ Parse test output and extract metrics
⏳ Generate test report
⏳ Present results to user
```

### Step 1: Determine Test Scope

Mark first todo as in_progress.

Plugin parameter: "$1"

- If "$1" is empty: Run ALL plugin tests
- If "$1" is provided: Run only the test for plugin "$1"

Mark first todo as completed.

### Step 2: Run Test Scripts

Mark second todo as in_progress.

**For all plugins (when "$1" is empty)**:

Run all tests using Bash:
```bash
./test/run-all-tests.sh
```

Capture the output and exit code.

**For specific plugin (when "$1" is provided)**:

Check if test script exists:
```bash
test -f test/plugins/$1/test-$1-hooks.sh && echo "exists" || echo "not found"
```

If not found, list available plugins:
```bash
ls -d test/plugins/*/test-*-hooks.sh 2>/dev/null | sed 's|test/plugins/\(.*\)/test-.*|\1|'
```

And report error: "Plugin '$1' not found. Available plugins: [list from above]"

If found, run the specific test script:
```bash
./test/plugins/$1/test-$1-hooks.sh
```

Capture the output and exit code.

Mark second todo as completed.

### Step 3: Parse Test Output

Mark third todo as in_progress.

Parse test output to extract:
- Total tests run
- Tests passed
- Tests failed
- Which specific tests failed (if any)

Mark third todo as completed.

### Step 4: Generate Test Report

Mark fourth todo as in_progress.

Create `.thoughts/` directory if needed:
```bash
mkdir -p .thoughts
```

3. Generate timestamp:
```bash
date +%Y%m%d-%H%M%S
```

4. Parse test output to extract:
   - Total tests run
   - Tests passed
   - Tests failed
   - Which specific tests failed (if any)

5. Generate report in markdown format:

```markdown
# Marketplace Plugin Test Results

**Date**: [current date/time]
**Tests Run**: [all|plugin-name]

## Overall Summary

Total: X tests
Passed: X tests
Failed: X tests

[IF ALL PASSED]
✅ All tests passed! The marketplace is healthy.

[IF SOME FAILED]
❌ Some tests failed. See details below.

## Detailed Results

[Include full test output showing which tests passed/failed]

## Failed Tests

[IF ANY FAILED]
[List each failed test with its output]

[IF NONE FAILED]
No failed tests.

## Next Steps

[IF FAILURES EXIST]
To debug failed tests:
1. Review the test output above
2. Check hook implementations in plugins/[plugin-name]/scripts/
3. Run individual tests: ./test/plugins/[plugin-name]/test-[plugin-name]-hooks.sh
4. Fix issues and rerun: /test-marketplace [plugin-name]

[IF ALL PASSED]
All tests passing! The marketplace is ready for use.

## Test Coverage

### Core Plugin (9 tests)
- Auto-format on .ex files
- Auto-format on .exs files
- Auto-format ignores non-Elixir files
- Compile check detects errors
- Compile check ignores non-Elixir files
- Pre-commit blocks on unformatted code
- Pre-commit shows compilation errors
- Pre-commit ignores non-commit git commands
- Pre-commit ignores non-git commands

### Credo Plugin (6 tests)
- Post-edit check detects violations
- Post-edit check works on .exs files
- Post-edit check ignores non-Elixir files
- Pre-commit blocks on violations
- Pre-commit ignores non-commit git commands
- Pre-commit ignores non-git commands
```

6. Write report to `.thoughts/test-marketplace-[timestamp].md`

Mark fourth todo as completed.

### Step 5: Present Results to User

Mark fifth todo as in_progress.

## Present Results to User

Show a CONCISE summary:

```markdown
# Test Results Summary

**Tests Run**: [all plugins | plugin-name]

[IF ALL PASSED]
✅ All tests passed!

[IF SOME FAILED]
❌ X/Y tests failed

**Failed Tests**:
[List failed test names]

**Detailed results**: `.thoughts/test-marketplace-[timestamp].md`

To rerun tests:
- All plugins: /test-marketplace
- Specific plugin: /test-marketplace [plugin-name]
```

Mark fifth todo as completed.

## Important Notes

- **Automated Testing**: Uses deterministic bash scripts that simulate hook execution
- **Fast Execution**: All 15 tests run in seconds
- **Deterministic**: Same input produces same output every time
- **Detailed Reports**: Full test output saved to `.thoughts/test-marketplace-[timestamp].md`
- **Exit Codes**: Tests verify expected exit codes (0 for success, 2 for blocking)
- **Pattern Matching**: Tests verify hook output contains expected patterns
- **JSON Validation**: Tests verify hook output JSON structure with jq

## Test Framework

The testing framework consists of:
- `test/test-hook.sh` - Base testing utilities
- `test/run-all-tests.sh` - Main test runner
- `test/plugins/core/test-core-hooks.sh` - Core plugin tests (9 tests)
- `test/plugins/credo/test-credo-hooks.sh` - Credo plugin tests (6 tests)

## Running Tests Manually

You can also run tests directly from the command line:

```bash
# Run all tests
./test/run-all-tests.sh

# Run core plugin tests only
./test/plugins/core/test-core-hooks.sh

# Run credo plugin tests only
./test/plugins/credo/test-credo-hooks.sh
```

## Test Output Format

Tests provide color-coded output:
- 🟡 [TEST] - Test is running
- ✅ PASS - Test passed
- ❌ FAIL - Test failed with details

Example:
```
Testing Core Plugin Hooks
================================

[TEST] Auto-format hook: Formats badly formatted .ex file
  ✅ PASS
[TEST] Compile check: Detects compilation errors
  ✅ PASS

================================
Test Summary
================================
Total:  9
Passed: 9
Failed: 0
================================
```
