# ex_unit Test Suite

This test suite validates the ex_unit@elixir plugin hooks.

## Test Structure

```
test/plugins/ex_unit/
├── README.md
├── precommit-test/          # Test project for pre-commit hook validation
│   ├── mix.exs
│   ├── lib/
│   │   └── calculator.ex
│   └── test/
│       ├── test_helper.exs
│       └── calculator_test.exs (contains 1 intentionally failing test)
└── test-ex-unit-hooks.sh    # Test runner script
```

## Running Tests

```bash
# Run all ex_unit plugin tests
./test/plugins/ex_unit/test-ex-unit-hooks.sh

# Or via QA command
/qa test ex_unit
```

## Test Cases

### Test 1: Pre-commit Hook Blocks on Test Failures

**Purpose**: Verify that the PreToolUse hook blocks git commits when tests fail

**Setup**:
- Project: `test/plugins/ex_unit/precommit-test/`
- Test file: `test/calculator_test.exs` contains one intentionally failing test
- Hook: PreToolUse with `git commit` command

**Test Steps**:
1. Simulate git commit command via hook input
2. Hook runs `mix test --stale` in the test project
3. Verify hook exits with code 2 (blocking)
4. Verify stderr contains test failure output

**Expected Behavior**:
- Exit code: 2 (blocks commit)
- Output: Contains "test will fail" or failure information
- Commit: Should be blocked

**Validation**:
```bash
echo '{"tool_input":{"command":"git commit -m test"},"cwd":"'$REPO_ROOT'/test/plugins/ex_unit/precommit-test"}' | \
  bash plugins/ex_unit/scripts/pre-commit-test.sh 2>&1
# Should exit with code 2 and show test failure
```

### Test 2: Pre-commit Hook Allows Commit When Tests Pass

**Purpose**: Verify hook allows commits when all tests pass

**Setup**:
- Same project, but with the failing test commented out or fixed
- Hook: PreToolUse with `git commit` command

**Test Steps**:
1. Fix the failing test temporarily
2. Simulate git commit command
3. Verify hook exits with code 0
4. Verify output is suppressed (JSON with suppressOutput: true)

**Expected Behavior**:
- Exit code: 0 (allows commit)
- Output: `{"suppressOutput": true}`
- Commit: Should proceed

### Test 3: Pre-commit Hook Ignores Non-commit Git Commands

**Purpose**: Verify hook doesn't run on `git status`, `git add`, etc.

**Setup**:
- Test project with failing tests
- Hook: PreToolUse with non-commit git command

**Test Steps**:
1. Simulate `git status` command
2. Verify hook exits with code 0 immediately
3. Verify no test execution occurred

**Expected Behavior**:
- Exit code: 0 (allows command)
- No test output
- Fast execution (< 1 second)

**Validation**:
```bash
echo '{"tool_input":{"command":"git status"},"cwd":"'$REPO_ROOT'/test/plugins/ex_unit/precommit-test"}' | \
  bash plugins/ex_unit/scripts/pre-commit-test.sh
# Should exit 0 immediately
```

### Test 4: Pre-commit Hook Ignores Non-git Commands

**Purpose**: Verify hook doesn't run on non-git bash commands

**Setup**:
- Test project
- Hook: PreToolUse with arbitrary bash command

**Test Steps**:
1. Simulate `ls -la` command
2. Verify hook exits with code 0 immediately
3. Verify no test execution occurred

**Expected Behavior**:
- Exit code: 0 (allows command)
- No test output
- Fast execution

**Validation**:
```bash
echo '{"tool_input":{"command":"ls -la"},"cwd":"'$REPO_ROOT'/test/plugins/ex_unit/precommit-test"}' | \
  bash plugins/ex_unit/scripts/pre-commit-test.sh
# Should exit 0 immediately
```

### Test 5: Pre-commit Hook Skips Non-Elixir Projects

**Purpose**: Verify hook gracefully skips when not in an Elixir project

**Setup**:
- Non-Elixir directory (no mix.exs)
- Hook: PreToolUse with git commit command

**Test Steps**:
1. Simulate git commit in non-Elixir directory
2. Verify hook exits with code 0
3. Verify suppressOutput JSON

**Expected Behavior**:
- Exit code: 0 (allows commit)
- Output: `{"suppressOutput": true}`
- No error messages

**Validation**:
```bash
echo '{"tool_input":{"command":"git commit -m test"},"cwd":"/tmp"}' | \
  bash plugins/ex_unit/scripts/pre-commit-test.sh
# Should exit 0 with suppressOutput
```

### Test 6: Pre-commit Hook Skips Projects Without Tests

**Purpose**: Verify hook skips Elixir projects that don't have a test/ directory

**Setup**:
- Create minimal Elixir project without test/
- Hook: PreToolUse with git commit

**Test Steps**:
1. Simulate git commit in project without tests
2. Verify hook exits with code 0
3. Verify suppressOutput JSON

**Expected Behavior**:
- Exit code: 0 (allows commit)
- Output: `{"suppressOutput": true}`
- No test execution

## Prerequisites

- ExUnit plugin must be implemented (scripts and hooks exist)
- Bash, jq, and standard Unix tools available
- Mix installed (for test project compilation)

## Test Execution Notes

- Tests simulate hook invocation by piping JSON to stdin
- Each test validates exit codes and output patterns
- Test project has intentional failures to verify blocking behavior
- Tests verify both blocking (exit 2) and non-blocking (exit 0) scenarios

## Success Criteria

All 6 tests should pass:
- ✅ Blocks commits when tests fail
- ✅ Allows commits when tests pass
- ✅ Ignores non-commit git commands
- ✅ Ignores non-git commands
- ✅ Skips non-Elixir projects
- ✅ Skips projects without tests

## Summary Format

After completing all tests, provide a summary:

```
✅ Test 1 - Blocks commits on test failures
✅ Test 2 - Allows commits when tests pass
✅ Test 3 - Ignores non-commit git commands
✅ Test 4 - Ignores non-git commands
✅ Test 5 - Skips non-Elixir projects
✅ Test 6 - Skips projects without tests

Overall result: PASS (6/6)
```
