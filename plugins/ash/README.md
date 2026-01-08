# ash

Automated code generation validation for Ash Framework projects. This plugin ensures your generated code stays in sync with your resource and domain definitions.

## Installation

### From GitHub (Recommended)

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install ash@elixir
```

### Local Development

```bash
/plugin marketplace add /path/to/claude-marketplace-elixir
/plugin install ash@elixir
```

## Features

### Post-Edit Code Generation Check (Non-blocking)

After editing `.ex` or `.exs` files in an Ash project, the plugin automatically runs `mix ash.codegen --check` to verify that all generated code is up-to-date. If code generation is needed, Claude receives context about what needs to be generated.

- Triggers on: File edits (Edit, Write, MultiEdit tools)
- File types: `.ex`, `.exs`
- Behavior: Informational only - does not block operations
- Timeout: 30 seconds

### Pre-Commit Code Generation Validation (Blocking)

Before allowing git commits, the plugin validates that all Ash-generated code is current by running `mix ash.codegen --check`. If code generation is needed, the commit is **blocked** and you must run `mix ash.codegen` first.

- Triggers on: `git commit` commands
- Behavior: **Blocks commits** if codegen is needed - commit will fail with error message
- Output: Shows what codegen tasks are pending via JSON permissionDecision
- Timeout: 45 seconds
- **Note**: Skips if project has a `precommit` alias (defers to precommit plugin)

## How It Works

The plugin only activates for Elixir projects with Ash as a dependency (detected by checking `mix.exs`). It automatically:

1. Finds your Mix project root
2. Runs `mix ash.codegen --check` to validate generated code
3. Provides feedback to Claude (post-edit) or blocks the operation (pre-commit) if code generation is needed

## Configuration

No configuration required. The plugin automatically detects Ash projects and runs appropriate validations.

## Workflow Example

1. You edit an Ash resource file to add a new attribute
2. The post-edit hook runs `mix ash.codegen --check` and informs Claude that code generation is needed
3. Claude can then run `mix ash.codegen` to generate the required code
4. When you commit, the pre-commit hook verifies all generated code is current
5. If codegen was forgotten, the commit is blocked with an informative error

## Ash Codegen vs Compilation

This plugin specifically validates **Ash code generation**, which is distinct from Elixir compilation:

**Ash Codegen checks**:
- Database migrations match resource definitions
- Snapshots are current with resource configuration
- All code generation tasks have been executed
- Resource extensions have generated required files

**NOT checked by Ash Codegen** (caught by compilation):
- Undefined functions or modules
- Type errors
- Syntax errors in resources
- General Elixir compilation issues

Use the `core@elixir` plugin alongside this plugin for comprehensive validation (formatting, compilation, and Ash codegen).

## Requirements

- Elixir project with `mix.exs`
- Ash Framework as a dependency (`{:ash, "~> 3.0"}` or later)
- At least one Ash data layer extension installed:
  - `{:ash_sqlite, "~> 0.2"}` - SQLite data layer
  - `{:ash_postgres, "~> 2.0"}` - PostgreSQL data layer
  - Or other Ash data layer packages
- `mix ash.codegen` task available (provided by Ash data layer extensions)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
