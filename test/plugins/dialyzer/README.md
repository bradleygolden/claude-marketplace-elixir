# Dialyzer Plugin Tests

This directory contains tests for the Dialyzer plugin hooks.

## Test Structure

```
dialyzer/
├── README.md                      # This file
├── test-dialyzer-hooks.sh        # Test runner script
└── precommit-test/                # Test project with type errors
    ├── mix.exs                    # Mix project file with dialyxir dependency
    ├── .gitignore                 # Ignore build artifacts
    └── lib/
        └── code_with_type_errors.ex  # Code with intentional type errors
```

## Running Tests

```bash
# Run all dialyzer tests
./test/plugins/dialyzer/test-dialyzer-hooks.sh

# Run all plugin tests (includes dialyzer)
./test/run-all-tests.sh

# Run via Claude Code slash command
/test-marketplace dialyzer
```

## Test Cases

1. **Pre-commit check blocks on type errors**: Verifies that `mix dialyzer` runs before `git commit` and blocks when type errors are found
2. **Pre-commit check ignores non-commit commands**: Verifies hook doesn't run for `git status` and similar commands
3. **Pre-commit check ignores non-git commands**: Verifies hook doesn't run for non-git commands like `npm install`

## Test Project Setup

The `precommit-test` directory contains a minimal Elixir project with intentional type errors:
- Functions with incorrect return types
- Mismatched type specifications
- These errors are detected by Dialyzer

## Prerequisites

Before running tests, ensure:
1. Dialyxir is installed in the test project: `cd test/plugins/dialyzer/precommit-test && mix deps.get`
2. PLT is built: `cd test/plugins/dialyzer/precommit-test && mix dialyzer --plt`

Note: The first PLT build may take several minutes.
