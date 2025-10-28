# ExDoc Plugin Test Suite

This test suite validates the ex_doc@elixir plugin for documentation validation.

## Prerequisites

Before running these tests:
- The ex_doc@elixir plugin must be installed
- Mix and Elixir must be available in PATH
- Git must be available for commit testing
- Test project dependencies must be installed: `cd test/plugins/ex_doc/precommit-test && mix deps.get`

## Test Structure

```
test/plugins/ex_doc/
├── README.md                      # This file
├── test-ex-doc-hooks.sh           # Test runner script
└── precommit-test/                # Test fixture project
    ├── mix.exs                    # Mix project with ex_doc dependency
    ├── lib/
    │   ├── valid_docs.ex          # Module with valid documentation
    │   └── invalid_docs.ex        # Module with undefined references
    └── .formatter.exs
```

## Hook Implementation

The ex_doc plugin implements one hook:

**Pre-commit check** (`plugins/ex_doc/scripts/pre-commit-check.sh`)
- **Trigger**: Before `git commit` commands (PreToolUse)
- **Action**: Runs `mix docs --warnings-as-errors`
- **Blocking**: Yes (exit 0 with JSON permissionDecision: "deny" blocks commit on validation failures)
- **Timeout**: 45 seconds
- **Dependency Check**: Only runs if `{:ex_doc` found in mix.exs

## Test Cases

### Test 1: Pre-Commit Hook Blocks on Documentation Warnings

#### Setup
1. Use test project with ExDoc dependency
2. Test file contains module with invalid documentation references
3. Example: `@doc "Calls \`NonExistent.function/1\`"`
4. Stage the file for commit

#### Test Steps
1. Run `git commit -m "Add module with bad docs"`
2. Observe hook execution and output

#### Expected Behavior
- Hook detects ExDoc dependency in mix.exs
- Runs `mix docs --warnings-as-errors`
- Documentation validation fails (undefined reference warnings)
- Commit is BLOCKED (exit 0 with JSON permissionDecision: "deny")
- Error output shows documentation warnings in JSON systemMessage via stdout

#### Validation
- Exit code is `0`
- JSON output contains `permissionDecision: "deny"`
- Output contains `"warning:"` text in systemMessage

---

### Test 2: Pre-Commit Hook with Documentation Warnings (Conceptual)

#### Setup
1. Use test project with ExDoc dependency
2. Ideally would use only valid_docs.ex to test success path
3. Currently uses same test project as Test 1 (contains invalid_docs.ex)

#### Test Steps
1. Run `git commit -m "Add documented module"`
2. Observe hook execution

#### Expected Behavior
- Hook detects ExDoc dependency
- Runs `mix docs --warnings-as-errors`
- **Note**: With current test fixture, this still produces warnings
- Commit is BLOCKED (exit 0 with JSON permissionDecision: "deny")
- Error output shows warnings

#### Validation
- Exit code is `0` with JSON `permissionDecision: "deny"` (blocks due to invalid_docs.ex in test project)
- Output contains `"warning:"` text

**Note**: This test demonstrates the blocking behavior. For a true "success path" test, you would need a separate test project with only valid documentation.

---

### Test 3: Pre-Commit Hook Ignores Non-Commit Git Commands

#### Setup
1. Use test project with ExDoc dependency
2. Prepare to run non-commit git command

#### Test Steps
1. Run `git status` command
2. Observe hook behavior

#### Expected Behavior
- Hook checks command for `git commit` pattern
- Command doesn't match
- Hook exits silently (exit code 0)
- Command executes normally
- No validation runs

#### Validation
- Exit code is `0`
- Output is empty

---

### Test 4: Pre-Commit Hook Ignores Non-Git Commands

#### Setup
1. Use any directory
2. Prepare to run non-git bash command

#### Test Steps
1. Run `npm install` command (or any non-git command)
2. Observe hook behavior

#### Expected Behavior
- Hook checks command for `git commit` pattern
- Command doesn't match
- Hook exits silently (exit code 0)
- Command executes normally
- No validation runs

#### Validation
- Exit code is `0`
- Output is empty

---

### Test 5: Pre-Commit Hook Skips When ExDoc Not in Dependencies

#### Setup
1. Use main repository root (which doesn't have ExDoc dependency)
2. Prepare git commit command

#### Test Steps
1. Run `git commit -m "test"` in directory without ExDoc
2. Observe hook behavior

#### Expected Behavior
- Hook finds Mix project (mix.exs exists)
- Hook checks for `{:ex_doc` in mix.exs
- ExDoc not found in dependencies
- Hook exits silently (exit code 0)
- Commit proceeds without validation
- No errors or output

#### Validation
- Exit code is `0`
- Output is empty

---

## Running the Tests

### Run All Tests

```bash
# From repository root
./test/plugins/ex_doc/test-ex-doc-hooks.sh
```

### Run Individual Tests

```bash
# From repository root
cd test/plugins/ex_doc/

# Source the test framework
source ../../test-hook.sh

# Run specific test
test_hook \
  "Pre-commit check: Blocks on documentation warnings" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  '{"tool_input":{"command":"git commit -m \"test\""},"cwd":"'$PWD'/precommit-test"}' \
  0 \
  "permissionDecision"
```

---

## Expected Output Format

### Successful Test Run

```
Testing ExDoc Plugin Hooks
================================

[TEST] Pre-commit check: Blocks on documentation warnings
  ✅ PASS
[TEST] Pre-commit check: Allows valid documentation
  ✅ PASS
[TEST] Pre-commit check: Ignores non-commit git commands
  ✅ PASS
[TEST] Pre-commit check: Ignores non-git commands
  ✅ PASS
[TEST] Pre-commit check: Skips when ExDoc not in dependencies
  ✅ PASS

================================
Test Summary
================================
Total:  5
Passed: 5
Failed: 0
================================
✅ ExDoc Plugin Tests completed successfully
```

### Failed Test Example

```
[TEST] Pre-commit check: Blocks on documentation warnings
  ❌ FAIL
  Expected exit code: 0 with JSON permissionDecision: "deny"
  Actual exit code: 0
  Expected output to contain: "permissionDecision"
  Actual output: ""
```

---

## Troubleshooting

### Test Dependencies Not Installed

If tests fail with "mix deps not available":

```bash
cd test/plugins/ex_doc/precommit-test
mix deps.get
```

### Hook Script Not Executable

If you get "Permission denied" errors:

```bash
chmod +x plugins/ex_doc/scripts/pre-commit-check.sh
```

### ExDoc Not Detecting Issues

Ensure `invalid_docs.ex` contains documentation that ExDoc will warn about:

```elixir
@doc """
Calls `NonExistent.function/1` that doesn't exist.
"""
def example, do: :ok
```

### Tests Pass When They Should Fail

Check that:
1. ExDoc is in the test project's mix.exs dependencies
2. The test fixture has invalid documentation references
3. Hook script has correct shebang: `#!/bin/bash`

### Hook Doesn't Block Commits

Verify:
1. Hook exits with `0` and uses JSON output with `permissionDecision: "deny"` for blocking
2. Output is sent to stdout as structured JSON with `systemMessage` field
3. PreToolUse matcher is "Bash" in hooks.json

---

## Notes

### Why PreToolUse Only?

The ExDoc plugin only implements PreToolUse hooks (no PostToolUse):
- **Performance**: `mix docs` can take 10-30+ seconds to generate documentation
- **Similar to Dialyzer**: Both are resource-intensive validation tools
- **Developer workflow**: Running on every edit would interrupt coding flow
- **Manual option**: Developers can run `mix docs` manually for immediate feedback

### Test Fixture Reality

- Test 2 is conceptual - it expects valid docs to pass (exit 0)
- Current test fixture always contains `invalid_docs.ex` which causes warnings
- Both Test 1 and Test 2 currently expect exit code 0 with JSON permissionDecision: "deny" (blocking)
- For a true success path test, create separate fixture with only valid docs

### Comparison with Other Plugins

| Plugin | Post-Edit Hooks | Pre-Commit Hooks | Rationale |
|--------|----------------|------------------|-----------|
| **Core** | 2 (format, compile) | 1 (validation) | Fast operations |
| **Credo** | 1 (suggest) | 1 (strict) | Medium speed |
| **Ash** | 1 (check) | 1 (validate) | Medium speed |
| **Dialyzer** | None | 1 (analyze) | Very slow (120s) |
| **ExDoc** | None | 1 (validate) | Slow (45s) |
| **Sobelow** | 1 (scan) | 1 (strict) | Medium speed |
