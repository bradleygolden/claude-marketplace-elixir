# mix_audit Plugin Test Suite

This test suite validates the mix_audit@elixir plugin for dependency security auditing.

**Prerequisite**: The mix_audit@elixir plugin must be installed before running this test.

## Test Structure

```
test/plugins/mix_audit/
├── README.md                     # This file - test documentation
├── test-mix-audit-hooks.sh       # Main test runner script
├── precommit-test/               # Test project WITH mix_audit
│   ├── mix.exs                   # Includes {:mix_audit, "~> 2.0"}
│   ├── lib/example.ex            # Sample Elixir module
│   └── .gitignore                # Ignore build artifacts
└── no-audit-test/                # Test project WITHOUT mix_audit
    ├── mix.exs                   # Empty deps array
    ├── lib/example.ex            # Sample Elixir module
    └── .gitignore                # Ignore build artifacts
```

The test suite validates mix_audit pre-commit hook behavior:
- Blocks commits with vulnerable dependencies
- Allows commits with clean dependencies
- Skips non-Elixir projects
- Skips projects without mix_audit
- Filters commands correctly (only git commit)

## Test 1: Pre-commit Hook - Blocks Vulnerable Dependencies

### Setup
1. Create a test Elixir project with mix_audit in dependencies
2. Add a dependency with known vulnerabilities to mix.exs
3. Run `mix deps.get` to lock the vulnerable version in mix.lock

### Test Steps
1. Initialize git repository: `git init && git add .`
2. Attempt to commit with vulnerable dependencies: `git commit -m "test"`
3. Observe the hook execution and blocking behavior

### Expected Behavior
- Hook should detect `git commit` command
- Hook should find Mix project root
- Hook should detect mix_audit in dependencies
- Hook should run `mix deps.audit`
- Hook should **block the commit** (exit code 2)
- Hook should output vulnerability details to stderr
- Output should be truncated if longer than 30 lines
- Commit should NOT complete

### Success Criteria
- ✅ Commit is blocked when vulnerabilities exist
- ✅ Vulnerability details are shown
- ✅ Exit code is 2 (blocking)

## Test 2: Pre-commit Hook - Allows Clean Dependencies

### Setup
1. Use same test project from Test 1
2. Update vulnerable dependency to patched version in mix.exs
3. Run `mix deps.update <package>` to update mix.lock
4. Verify clean audit: `mix deps.audit` should exit 0

### Test Steps
1. Attempt to commit with clean dependencies: `git commit -m "fixed vulnerabilities"`
2. Observe the hook execution

### Expected Behavior
- Hook should detect `git commit` command
- Hook should run `mix deps.audit`
- Hook should find no vulnerabilities (exit 0)
- Hook should **allow the commit** (exit 0)
- Commit should complete successfully

### Success Criteria
- ✅ Commit succeeds when no vulnerabilities
- ✅ No blocking or error output
- ✅ Exit code is 0

## Test 3: Pre-commit Hook - Skips Non-Elixir Projects

### Setup
1. Create a non-Elixir project directory (no mix.exs)
2. Initialize git repository: `git init`
3. Create a dummy file: `echo "test" > README.md && git add README.md`

### Test Steps
1. Attempt to commit: `git commit -m "test"`
2. Observe hook behavior

### Expected Behavior
- Hook should detect `git commit` command
- Hook should attempt to find Mix project root
- Hook should NOT find mix.exs
- Hook should exit 0 (allow commit)
- Commit should complete

### Success Criteria
- ✅ Hook exits silently when no Mix project found
- ✅ Commit is not blocked
- ✅ Exit code is 0

## Test 4: Pre-commit Hook - Skips When mix_audit Not Installed

### Setup
1. Create a test Elixir project WITHOUT mix_audit in dependencies
2. Initialize git: `git init && git add .`

### Test Steps
1. Attempt to commit: `git commit -m "test"`
2. Observe hook behavior

### Expected Behavior
- Hook should detect `git commit` command
- Hook should find Mix project root
- Hook should check for mix_audit in mix.exs
- Hook should NOT find `{:mix_audit` pattern
- Hook should exit 0 (allow commit)
- Commit should complete

### Success Criteria
- ✅ Hook exits silently when mix_audit not in dependencies
- ✅ Commit is not blocked
- ✅ Exit code is 0

## Test 5: Pre-commit Hook - Skips Non-Commit Commands

### Setup
1. Use test project with mix_audit from Test 1

### Test Steps
1. Run various non-commit bash commands:
   - `git status`
   - `git diff`
   - `ls -la`
   - `mix deps.get`
2. Observe hook behavior

### Expected Behavior
- Hook should check each command
- Hook should NOT find "git commit" pattern
- Hook should exit 0 immediately for each
- Commands should execute normally

### Success Criteria
- ✅ Hook does not interfere with non-commit commands
- ✅ Commands execute normally
- ✅ No audit runs for non-commit commands

## Test 6: Output Truncation

### Setup
1. Create test project with multiple vulnerable dependencies (to generate long output)

### Test Steps
1. Attempt to commit with many vulnerabilities
2. Check the output length

### Expected Behavior
- If output exceeds 30 lines:
  - First 30 lines are shown
  - "[Output truncated: showing 30 of X lines]" message appears
  - "Run 'mix deps.audit' to see the full output" instruction appears
- If output is under 30 lines:
  - Full output is shown
  - No truncation message

### Success Criteria
- ✅ Long output is truncated appropriately
- ✅ Truncation message is clear
- ✅ Full command is provided for reference

## Running the Test Suite

```bash
# Run the test script
./test/plugins/mix_audit/test-mix-audit-hooks.sh
```

## Summary Format

After completing all tests, provide a summary:

```
✅ Test 1 - Blocks vulnerable dependencies
✅ Test 2 - Allows clean dependencies
✅ Test 3 - Skips non-Elixir projects
✅ Test 4 - Skips when mix_audit not installed
✅ Test 5 - Skips non-commit commands
✅ Test 6 - Output truncation works correctly

Tests passed: 6/6
Overall result: PASS
```

## Expected Test Output

### Successful Test Run

```
Testing mix_audit Plugin Hooks
================================

[TEST] Pre-commit check: Ignores non-commit git commands (git status)
  ✅ PASS
[TEST] Pre-commit check: Ignores non-git commands (npm install)
  ✅ PASS
[TEST] Pre-commit check: Ignores non-Elixir projects
  ✅ PASS
[TEST] Pre-commit check: Skips when mix_audit not in dependencies
  ✅ PASS
[TEST] Pre-commit check: Attempts to run mix deps.audit when mix_audit present
  ✅ PASS: Hook attempted to execute mix deps.audit

================================
Test Summary
================================
Total:  5
Passed: 5
Failed: 0
================================
```

### Failed Test Example

```
Testing mix_audit Plugin Hooks
================================

[TEST] Pre-commit check: Ignores non-commit git commands (git status)
  ✅ PASS
[TEST] Pre-commit check: Skips when mix_audit not in dependencies
  ❌ FAIL: Expected exit code 0, got 1
  Output:
    jq: error parsing JSON

================================
Test Summary
================================
Total:  5
Passed: 4
Failed: 1
================================
```

## Troubleshooting Tests

### Test Failure: "jq: error parsing JSON"

**Cause**: JSON input to hook script is malformed or missing

**Solution**:
1. Check that the JSON structure matches expected format:
   ```json
   {"tool_input":{"command":"..."},"cwd":"..."}
   ```
2. Verify jq is installed: `which jq`
3. Test JSON parsing manually: `echo '{"test":"value"}' | jq .`

### Test Failure: "Hook script not found"

**Cause**: Script path is incorrect or file doesn't exist

**Solution**:
1. Verify script exists: `ls plugins/mix_audit/scripts/pre-commit-check.sh`
2. Check script is executable: `ls -l plugins/mix_audit/scripts/pre-commit-check.sh`
3. Make executable if needed: `chmod +x plugins/mix_audit/scripts/pre-commit-check.sh`

### Test Failure: "mix: command not found"

**Cause**: Elixir/Mix not installed or not in PATH

**Solution**:
1. Install Elixir: `brew install elixir` (macOS) or equivalent
2. Verify installation: `mix --version`
3. Check PATH: `echo $PATH | grep elixir`

### Test Failure: Hook doesn't skip when expected

**Cause**: Logic in pre-commit-check.sh may have issues

**Solution**:
1. Run script manually with test input:
   ```bash
   echo '{"tool_input":{"command":"git status"},"cwd":"/tmp"}' | \
     bash plugins/mix_audit/scripts/pre-commit-check.sh
   ```
2. Check exit code: `echo $?` (should be 0)
3. Review script logic for command filtering (line 22)

### All tests pass but functionality doesn't work in Claude Code

**Cause**: Plugin may not be installed or enabled correctly

**Solution**:
1. Reload marketplace: `/plugin marketplace reload`
2. Verify installation: `/plugin list`
3. Check settings.json has `"mix_audit@elixir": true`
4. Reinstall if needed: `/plugin uninstall mix_audit@elixir && /plugin install mix_audit@elixir`

## Maintenance

### Updating Test Fixtures

To update test projects (`precommit-test/` or `no-audit-test/`):

1. Navigate to test fixture: `cd test/plugins/mix_audit/precommit-test`
2. Update `mix.exs` with new dependencies or versions
3. Run `mix deps.get` to update `mix.lock`
4. Commit changes to test fixtures

### Adding New Test Cases

To add a new test to the suite:

1. Edit `test-mix-audit-hooks.sh`
2. Add new `test_hook` call following existing pattern:
   ```bash
   test_hook \
     "Test description" \
     "plugins/mix_audit/scripts/pre-commit-check.sh" \
     '{"tool_input":{"command":"..."},"cwd":"..."}' \
     0 \
     "expected output pattern"
   ```
3. Update this README with new test documentation
4. Run test suite to verify: `./test/plugins/mix_audit/test-mix-audit-hooks.sh`

### Updating for Plugin Changes

When the plugin hook script changes:

1. Review changes in `plugins/mix_audit/scripts/pre-commit-check.sh`
2. Identify affected test scenarios
3. Update test expectations in this README
4. Update test assertions in `test-mix-audit-hooks.sh` if needed
5. Run full test suite to verify all tests still pass
