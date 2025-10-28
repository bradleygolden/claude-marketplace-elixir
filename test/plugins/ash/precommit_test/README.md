# PrecommitTest - Ash Plugin Pre-Commit Hook Test

This is a test Ash application used to verify the pre-commit code generation validation hook.

## Purpose

Tests the `PreToolUse` hook that runs before `git commit` commands in an Ash project. The hook should **block commits** when Ash code generation is out of sync with resource definitions.

## Project Structure

- **Ash Domain**: `PrecommitTest.Blog`
- **Ash Resource**: `PrecommitTest.Blog.Post`
  - Attributes: `title` (string, required), `body` (string)
  - Primary Key: `id` (uuid)
- **Data Layer**: AshSqlite with SQLite database
- **Repo**: `PrecommitTest.Repo`

## Test State

This project is configured to test the pre-commit hook's ability to block commits when code generation is pending:

- Resource definitions exist in `lib/precommit_test/blog/post.ex`
- Database configuration is present in `config/`
- The project may have pending migrations or snapshots that need generation

## Setup

```bash
cd test/plugins/ash/precommit_test
mix deps.get
```

To initialize the database (when needed for testing):

```bash
mix ash.setup
```

## Expected Hook Behavior

When the pre-commit hook runs before `git commit` commands:

1. **If codegen is needed**: Hook **blocks the commit** with exit 0 and JSON output (`permissionDecision: "deny"`), sends error details in `systemMessage` via stdout showing what codegen tasks are pending
2. **If codegen is current**: Hook allows the commit to proceed (exit code 0)
3. **If not a git commit command**: Hook silently exits (doesn't run validation for other git operations)
4. **If not an Ash project**: Hook silently exits

## Testing

This project is used by `test/plugins/ash/test-ash-hooks.sh` to verify:

- Pre-commit hook blocks commits when codegen is needed
- Hook only runs on `git commit` commands (ignores `git status`, `git push`, etc.)
- Hook ignores non-git bash commands

## Dependencies

- `ash` ~> 3.0 - Ash Framework
- `ash_sqlite` ~> 0.2 - SQLite data layer for Ash
- `sourceror` - Code manipulation (dev/test only)
- `igniter` - Code generation (dev/test only)
