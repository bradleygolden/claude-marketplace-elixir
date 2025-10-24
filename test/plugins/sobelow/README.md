# Sobelow Plugin Test Suite

This test suite validates the sobelow@elixir plugin hooks and scripts.

**Prerequisite**: The sobelow@elixir plugin must be installed before running this test.

## Test Structure

```
test/plugins/sobelow/
├── README.md                    # This file
├── test-sobelow-hooks.sh        # Main test runner
├── postedit-test/               # Test project for PostToolUse hook
│   ├── mix.exs                  # Project with sobelow dependency
│   ├── lib/
│   │   └── vulnerable_code.ex   # Code with security issues
│   └── test/
│       └── test_helper.exs      # Test helper (.exs file)
└── precommit-test/              # Test project for PreToolUse hook
    ├── mix.exs                  # Project with sobelow dependency
    └── lib/
        └── vulnerable_code.ex   # Code with security issues
```

## Test Cases

### Test 1: Post-edit Check - Detects Security Issues

**Purpose**: Verify PostToolUse hook detects Sobelow security findings after editing a file.

**Setup**:
- Test project at `test/plugins/sobelow/postedit-test/`
- `mix.exs` includes `{:sobelow, ...}` dependency
- `lib/vulnerable_code.ex` contains intentional security issues (e.g., XSS, SQL injection)

**Test Steps**:
1. Simulate Edit tool with `file_path` pointing to `vulnerable_code.ex`
2. Pass JSON input to `post-edit-check.sh` via stdin
3. Capture output and exit code

**Expected Behavior**:
- Exit code: `0` (non-blocking)
- Output: JSON with `hookSpecificOutput.additionalContext` containing security findings
- JSON structure: Valid and includes "additionalContext" field
- Output should mention Sobelow findings and suppression options

**Validation**:
```bash
jq -e '.hookSpecificOutput | has("additionalContext")'
```

---

### Test 2: Post-edit Check - Works on .exs Files

**Purpose**: Verify the hook processes both `.ex` and `.exs` files.

**Setup**:
- Test project at `test/plugins/sobelow/postedit-test/`
- `test/test_helper.exs` file exists

**Test Steps**:
1. Simulate Edit tool with `file_path` pointing to `test_helper.exs`
2. Pass JSON input to `post-edit-check.sh`

**Expected Behavior**:
- Exit code: `0`
- Output: JSON with `hookSpecificOutput` structure
- Should process `.exs` files the same as `.ex` files

**Validation**:
```bash
jq -e '.hookSpecificOutput | has("hookEventName")'
```

---

### Test 3: Post-edit Check - Ignores Non-Elixir Files

**Purpose**: Verify the hook silently skips non-Elixir files.

**Setup**:
- Non-Elixir file (e.g., `README.md`)

**Test Steps**:
1. Simulate Edit tool with `file_path` pointing to `README.md`
2. Pass JSON input to `post-edit-check.sh`

**Expected Behavior**:
- Exit code: `0`
- Output: Empty or minimal (hook exits early)
- Should not attempt to run Sobelow

**Validation**:
- Exit code is `0`
- No error output

---

### Test 4: Post-edit Check - Suppresses Output When No Sobelow Dependency

**Purpose**: Verify the hook exits gracefully when Sobelow is not in the project.

**Setup**:
- Project without sobelow in mix.exs dependencies

**Test Steps**:
1. Simulate Edit tool with `file_path` in a project without Sobelow
2. Pass JSON input to `post-edit-check.sh`

**Expected Behavior**:
- Exit code: `0`
- Output: JSON with `suppressOutput: true`

**Validation**:
```bash
jq -e '.suppressOutput == true'
```

---

### Test 5: Pre-commit Check - Blocks on Security Violations

**Purpose**: Verify PreToolUse hook blocks commits when security issues are found.

**Setup**:
- Test project at `test/plugins/sobelow/precommit-test/`
- `lib/vulnerable_code.ex` contains security violations

**Test Steps**:
1. Simulate Bash tool with `command: "git commit -m 'test'"`
2. Set `cwd` to the test project directory
3. Pass JSON input to `pre-commit-check.sh`

**Expected Behavior**:
- Exit code: `2` (blocks the commit)
- Output: Contains "sobelow" and security findings
- Should provide guidance on fixing or suppressing

**Validation**:
- Exit code is `2`
- Output contains "sobelow" string (case-insensitive)

---

### Test 6: Pre-commit Check - Ignores Non-commit Git Commands

**Purpose**: Verify the hook only runs on `git commit` commands.

**Setup**:
- Any git command except commit (e.g., `git status`)

**Test Steps**:
1. Simulate Bash tool with `command: "git status"`
2. Pass JSON input to `pre-commit-check.sh`

**Expected Behavior**:
- Exit code: `0` (allows the command)
- Output: Empty or minimal (hook exits early)

**Validation**:
- Exit code is `0`

---

### Test 7: Pre-commit Check - Ignores Non-git Commands

**Purpose**: Verify the hook doesn't interfere with non-git bash commands.

**Setup**:
- Non-git command (e.g., `npm install`)

**Test Steps**:
1. Simulate Bash tool with `command: "npm install"`
2. Pass JSON input to `pre-commit-check.sh`

**Expected Behavior**:
- Exit code: `0` (allows the command)
- Output: Empty or minimal (hook exits early)

**Validation**:
- Exit code is `0`

---

### Test 8: Pre-commit Check - Allows Commit When No Issues

**Purpose**: Verify successful commits when no security issues exist.

**Setup**:
- Test project with clean code (no security issues)
- OR test project with `.sobelow-skips` file that skips all findings

**Test Steps**:
1. Simulate Bash tool with `command: "git commit -m 'test'"`
2. Set `cwd` to clean project
3. Pass JSON input to `pre-commit-check.sh`

**Expected Behavior**:
- Exit code: `0` (allows the commit)
- Output: JSON with `suppressOutput: true` or empty

**Validation**:
- Exit code is `0`

---

## Running the Tests

### Run All Tests

```bash
./test/plugins/sobelow/test-sobelow-hooks.sh
```

### Run via Main Test Runner

```bash
./test/run-all-tests.sh
```

### Run via QA Command

```bash
/qa test sobelow
```

## Test Project Setup

### Creating Test Projects

Each test project needs:

1. **mix.exs** with Sobelow dependency:
```elixir
defmodule TestProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_project,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
    ]
  end
end
```

2. **Vulnerable code** for testing detection:
```elixir
defmodule VulnerableCode do
  # SQL Injection risk
  def unsafe_query(user_input) do
    query = "SELECT * FROM users WHERE name = '#{user_input}'"
    Repo.query(query)
  end

  # XSS risk
  def unsafe_html(user_input) do
    raw("<div>#{user_input}</div>")
  end
end
```

3. **Clean code** for testing success case (or use `.sobelow-skips`)

## Expected Output Format

### Successful Test Run

```
Testing Sobelow Plugin Hooks
========================================

[TEST] Post-edit check: Detects security violations
  ✅ PASS

[TEST] Post-edit check: Works on .exs files
  ✅ PASS

[TEST] Post-edit check: Ignores non-Elixir files
  ✅ PASS

[TEST] Post-edit check: Suppresses when no Sobelow dependency
  ✅ PASS

[TEST] Pre-commit check: Blocks on security violations
  ✅ PASS

[TEST] Pre-commit check: Ignores non-commit git commands
  ✅ PASS

[TEST] Pre-commit check: Ignores non-git commands
  ✅ PASS

[TEST] Pre-commit check: Allows commit when no issues
  ✅ PASS

========================================
Tests passed: 8/8
Tests failed: 0/8

Overall result: PASS
```

### Failed Test Example

```
[TEST] Pre-commit check: Blocks on security violations
  ❌ FAIL: Expected exit code 2, got 0
  Output:
    {"suppressOutput": true}
```

## Troubleshooting Tests

### Test project dependencies not installed

Run in each test project:
```bash
cd test/plugins/sobelow/postedit-test && mix deps.get
cd test/plugins/sobelow/precommit-test && mix deps.get
```

### Sobelow not finding issues

Ensure `lib/vulnerable_code.ex` has actual security issues that Sobelow detects.

### Hook scripts not executable

```bash
chmod +x plugins/sobelow/scripts/post-edit-check.sh
chmod +x plugins/sobelow/scripts/pre-commit-check.sh
```

## Maintenance

### Updating Test Projects

When Sobelow detection logic changes:
1. Update `vulnerable_code.ex` to include current vulnerability patterns
2. Re-run tests to verify detection
3. Update expected output patterns if needed

### Adding New Tests

Follow the pattern in existing test files:
1. Define test purpose and setup
2. Use `test_hook` or `test_hook_json` functions from `test/test-hook.sh`
3. Validate both exit codes and output patterns
4. Document in this README
