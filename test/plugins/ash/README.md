# Ash Plugin Tests

This directory contains automated tests for the ash plugin hooks.

## Running Tests

### Run all ash plugin tests:
```bash
./test/plugins/ash/test-ash-hooks.sh
```

### Run all marketplace tests (includes core + credo + ash):
```bash
./test/run-all-tests.sh
```

### Via Claude Code slash command:
```
/qa test ash
```

## Test Projects

The ash plugin has test projects that verify hook behavior for Ash Framework code generation:

### 1. postedit_test/
- **Purpose**: Tests the post-edit check hook (PostToolUse, non-blocking)
- **Contains**: Ash project with resources that need code generation
- **Expected behavior**: Provides context to Claude when codegen is needed after editing

### 2. precommit_test/
- **Purpose**: Tests the pre-commit check hook (PreToolUse, blocking)
- **Contains**: Ash project with resources that need code generation
- **Expected behavior**: Blocks git commits when codegen is needed

## Test Coverage

The automated test suite includes 6 tests:

**Post-edit check hook**:
- ✅ Detects when codegen is needed
- ✅ Works on .exs files
- ✅ Ignores non-Elixir files

**Pre-commit check hook**:
- ✅ Blocks commits when codegen is needed
- ✅ Ignores non-commit git commands
- ✅ Ignores non-git commands

## Hook Implementation

The ash plugin implements two hooks:

1. **Post-edit check** (`scripts/post-edit-check.sh`)
   - Trigger: After Edit/Write tools on .ex/.exs files
   - Action: Runs `mix ash.codegen --check`
   - Blocking: No (provides context when codegen needed)
   - Output: Truncated to 50 lines

2. **Pre-commit check** (`scripts/pre-commit-check.sh`)
   - Trigger: Before `git commit` commands
   - Action: Runs `mix ash.codegen --check`
   - Blocking: Yes (exit code 2 when codegen needed)

## Ash Codegen

**What `mix ash.codegen --check` validates**:
- Database migrations are generated for resource changes
- Snapshots are up-to-date with resource definitions
- All code generation tasks have been run

**When codegen is needed**:
- After adding/modifying attributes on Ash resources
- After changing domains or resource configurations
- After adding new resources
- When database extensions need migration files

## Prerequisites

Before running tests, ensure:
1. Test projects have dependencies installed (including Ash)
2. The ash plugin is installed in Claude Code:

```
/plugin marketplace add /path/to/marketplace
/plugin install ash@elixir
```

## Test Projects Structure

### postedit_test/
- **Ash Resources**: PosteditTest.Accounts.User (email, name attributes)
- **Data Layer**: AshSqlite with SQLite database
- **Domain**: PosteditTest.Accounts
- **State**: Intentionally has no generated migrations (codegen needed)
- **Purpose**: Tests post-edit hook detection of pending codegen

### precommit_test/
- **Ash Resources**: PrecommitTest.Blog.Post (title, body attributes)
- **Data Layer**: AshSqlite with SQLite database
- **Domain**: PrecommitTest.Blog
- **State**: Intentionally has no generated migrations (codegen needed)
- **Purpose**: Tests pre-commit hook blocking behavior

Both projects were created using:
```bash
sh <(curl 'https://ash-hq.org/install/PROJECT_NAME') && \
cd PROJECT_NAME && \
mix igniter.install ash ash_sqlite --setup --yes
```
