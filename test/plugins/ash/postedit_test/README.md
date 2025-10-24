# PosteditTest - Ash Plugin Post-Edit Hook Test

This is a test Ash application used to verify the post-edit code generation check hook.

## Purpose

Tests the `PostToolUse` hook that runs after editing Elixir files in an Ash project. The hook should detect when Ash code generation is out of sync with resource definitions.

## Project Structure

- **Ash Domain**: `PosteditTest.Accounts`
- **Ash Resource**: `PosteditTest.Accounts.User`
  - Attributes: `email` (string), `name` (string)
  - Primary Key: `id` (uuid)
- **Data Layer**: AshSqlite with SQLite database
- **Repo**: `PosteditTest.Repo`

## Test State

This project is configured to test the post-edit hook's ability to detect pending code generation:

- Resource definitions exist in `lib/postedit_test/accounts/user.ex`
- Database configuration is present in `config/`
- The project may have pending migrations or snapshots that need generation

## Setup

```bash
cd test/plugins/ash/postedit_test
mix deps.get
```

To initialize the database (when needed for testing):

```bash
mix ash.setup
```

## Expected Hook Behavior

When the post-edit hook runs after editing `.ex` or `.exs` files:

1. **If codegen is needed**: Hook outputs JSON with `additionalContext` containing the output of `mix ash.codegen --check`, informing Claude that code generation is pending
2. **If codegen is current**: Hook outputs `suppressOutput: true` to avoid unnecessary noise
3. **If not an Ash project**: Hook silently suppresses output

## Testing

This project is used by `test/plugins/ash/test-ash-hooks.sh` to verify:

- Post-edit hook detects pending codegen
- Hook works on both `.ex` and `.exs` files
- Hook ignores non-Elixir files

## Dependencies

- `ash` ~> 3.0 - Ash Framework
- `ash_sqlite` ~> 0.2 - SQLite data layer for Ash
- `sourceror` - Code manipulation (dev/test only)
- `igniter` - Code generation (dev/test only)
