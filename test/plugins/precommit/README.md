# Precommit Plugin Tests

Tests for the precommit plugin that runs `mix precommit` before git commits.

## Test Structure

```
precommit/
├── test-precommit-hooks.sh      # Main test script
├── README.md                     # This file
├── precommit-test-pass/          # Mix project with passing precommit
│   ├── mix.exs                   # Has precommit alias
│   ├── lib/test.ex               # Valid code
│   └── test/                     # Passing tests
├── precommit-test-fail/          # Mix project with failing precommit
│   ├── mix.exs                   # Has precommit alias
│   └── lib/test.ex               # Code with unused variable warning
└── no-precommit-alias/           # Mix project without precommit alias
    ├── mix.exs                   # No precommit alias
    └── lib/test.ex               # Valid code
```

## Running Tests

```bash
# Run precommit plugin tests only
./test/plugins/precommit/test-precommit-hooks.sh

# Run all plugin tests
./test/run-all-tests.sh
```

## Test Cases

| # | Test | Expected |
|---|------|----------|
| 1 | Blocks when precommit fails | `permissionDecision: deny` |
| 2 | Allows when precommit passes | `suppressOutput: true` |
| 3 | Skips when no alias exists | `suppressOutput: true` |
| 4 | Ignores non-commit git commands | Exit 0, no output |
| 5 | Ignores non-git commands | Exit 0, no output |
| 6 | Skips non-Elixir projects | `suppressOutput: true` |

## Test Projects

### precommit-test-pass
- Has `precommit` alias defined
- Valid Elixir code (no warnings)
- Passing test suite
- Expected: `mix precommit` passes, commit allowed

### precommit-test-fail
- Has `precommit` alias defined
- Code with intentional unused variable warning
- `--warnings-as-errors` causes compilation failure
- Expected: `mix precommit` fails, commit blocked

### no-precommit-alias
- Standard Mix project
- No `precommit` alias in mix.exs
- Expected: Plugin skips, defers to other plugins
