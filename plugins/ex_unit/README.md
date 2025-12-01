# ex_unit

ExUnit testing automation plugin that validates tests pass before git commits.

## Overview

This plugin automatically runs ExUnit tests before git commits, preventing broken code from being committed. It uses `mix test --stale` to intelligently run only tests for modules that have changed, keeping validation fast and efficient.

## Installation

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install ex_unit@elixir
```

## Features

### Pre-commit Test Validation

**When it runs**: Before any `git commit` command

**What it does**: Runs `mix test --stale` to validate tests pass for changed modules

**Behavior**:
- ✅ **Fast**: Only runs tests for modules that changed (`--stale` flag)
- ✅ **Blocking**: Prevents commits if tests fail (via JSON permissionDecision: "deny")
- ✅ **Smart**: Skips if not an Elixir project or no tests exist
- ✅ **Informative**: Shows test failures with truncated output (50 lines max)

**Performance**: Typically 5-30 seconds depending on number of changed modules

## How It Works

### The `--stale` Flag

The key to performance is ExUnit's `--stale` flag, which only runs tests for modules that have been modified since the last test run. This means:

- First commit after changes: Tests run for affected modules only
- Subsequent commits without code changes: No tests run (already validated)
- Large test suites: Only relevant subset runs

### Hook Details

**Hook Type**: PreToolUse (blocks before bash commands execute)
**Matcher**: Filters for `git commit` commands only
**Timeout**: 60 seconds
**Note**: Skips if project has a `precommit` alias (defers to precommit plugin)
**Blocking Behavior**:
- Hook always exits with `0` (success)
- Blocking decision communicated via JSON output with `permissionDecision: "deny"`
- When tests fail: Outputs JSON with permissionDecision: "deny" and test failure details
- When tests pass: Outputs JSON with suppressOutput: true

## Usage

Once installed, the plugin works automatically:

```bash
# Make changes to your code
$ edit lib/accounts.ex
$ edit test/accounts_test.exs

# Try to commit
$ claude
> commit these changes

# Plugin runs automatically
Running stale tests for changed modules...

# If tests pass:
✓ Tests passed
[Commit proceeds]

# If tests fail:
✗ 1 test failed

1) test creates user (MyApp.AccountsTest)
   test/accounts_test.exs:12
   Expected: {:ok, %User{}}
   Got: {:error, :invalid}

⚠️ Commit blocked. Fix failing tests before committing.
```

## Configuration

No configuration needed! The plugin:
- Auto-detects Mix projects (looks for `mix.exs`)
- Auto-detects test directory (looks for `test/`)
- Uses sensible defaults for all options

## When Tests Run

The plugin runs tests **only** when:
1. Command is a `git commit` (not status, add, etc.)
2. Current directory is part of a Mix project
3. Project has a `test/` directory

**It skips** for:
- Non-Elixir projects
- Projects without tests
- Git commands other than commit
- Non-git bash commands

## Performance Tips

The `--stale` flag makes this fast, but you can optimize further:

### 1. Run Full Suite Manually
```bash
# Before committing, run full suite yourself
$ mix test

# Then commit - stale detection means nothing runs again
$ git commit -m "message"
```

### 2. Keep Tests Fast
- Use `async: true` in test modules when possible
- Mock external dependencies
- Use `setup` blocks efficiently

### 3. Commit Frequently
Since only changed tests run, frequent commits keep validation fast

## Troubleshooting

### "Tests timed out"

If tests exceed 60 seconds, they'll timeout. This usually means:
- Test suite is very large (even with `--stale`)
- Tests are slow (network calls, etc.)
- Many modules changed at once

**Solution**: Run `mix test --stale` manually to see which tests are slow

### "No tests run but commit blocked"

This shouldn't happen, but if it does:
- Check for compilation errors: `mix compile`
- Verify test files exist: `ls test/`
- Run tests manually: `mix test --stale`

### "Want to skip tests for this commit"

The plugin blocks commits with failing tests intentionally. Options:
1. Fix the failing tests (recommended)
2. Temporarily disable plugin: `/plugin uninstall ex_unit@elixir`
3. Use `--no-verify` flag: Not recommended, bypasses all hooks

## Examples

### Example 1: Single Module Change

```bash
# Edit one file
$ edit lib/accounts.ex

# Only accounts_test.exs runs (2-5 seconds)
$ git commit -m "update accounts"
Running stale tests...
1 test file, 5 tests, 0 failures
✓ Tests passed
```

### Example 2: Multiple Module Changes

```bash
# Edit several files
$ edit lib/accounts.ex lib/users.ex lib/posts.ex

# Three test files run (10-20 seconds)
$ git commit -m "update multiple modules"
Running stale tests...
3 test files, 24 tests, 0 failures
✓ Tests passed
```

### Example 3: Test Failure

```bash
# Break a test
$ edit test/accounts_test.exs

$ git commit -m "broken test"
Running stale tests...

1) test creates user (AccountsTest)
   test/accounts_test.exs:12
   Assertion failed

✗ Commit blocked - fix tests first
```

## Comparison with Other Approaches

### vs. Manual Testing
- **Manual**: Remember to run `mix test` before every commit
- **ex_unit plugin**: Automatic, never forget

### vs. Full Test Suite Pre-commit
- **Full suite**: 30-120+ seconds every commit
- **ex_unit plugin**: 5-30 seconds (only changed modules)

### vs. CI/CD Only
- **CI only**: Broken code reaches remote repository
- **ex_unit plugin**: Catch failures locally before push

## Philosophy

This plugin follows the "80/20 rule":
- **80% of value**: Prevent committing broken tests
- **20% of complexity**: One simple hook with `--stale` flag

It doesn't:
- Run tests on every file edit (too slow for dev flow)
- Require configuration (works out of the box)
- Support custom flags (keeps it simple)
- Replace CI/CD (complements it)

## Related Plugins

- **core@elixir**: Auto-formatting and compilation checks
- **credo@elixir**: Code quality analysis
- **dialyzer@elixir**: Type checking

Together, these create a comprehensive pre-commit validation suite.

## Contributing

Issues and pull requests welcome at:
https://github.com/bradleygolden/claude-marketplace-elixir

## License

MIT
