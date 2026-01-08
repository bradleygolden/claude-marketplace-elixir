# Elixir Plugin Tests

Tests for the combined `elixir@elixir` plugin hooks.

## Test Fixtures

### postedit-test/

A minimal Mix project with intentional compilation errors for testing post-edit hooks.

- `lib/broken_code.ex` - Has undefined variable (compilation error)

### precommit-test/

A minimal Mix project with intentional issues for testing pre-commit hooks.

- `lib/unformatted.ex` - Intentionally unformatted code
- `lib/compilation_error.ex` - Has undefined variable (compilation error)

## Running Tests

```bash
./test-elixir-hooks.sh
```

Or via the main test runner:

```bash
../../run-all-tests.sh
```

## Test Coverage

### PostToolUse (post-edit.sh)

| Test | Description |
|------|-------------|
| Compilation errors | Detects and reports compilation errors |
| Non-Elixir files | Ignores non-Elixir files silently |

### PreToolUse (pre-commit.sh)

| Test | Description |
|------|-------------|
| Validation failures | Blocks commit on format/compile failures |
| Non-commit commands | Ignores `git status`, `git log`, etc. |
| Non-git commands | Ignores `ls`, `cat`, etc. |
| Git -C flag | Uses -C directory for project detection |
| Invalid -C path | Falls back to CWD when -C path invalid |
| Precommit alias | Defers to `mix precommit` when present |
