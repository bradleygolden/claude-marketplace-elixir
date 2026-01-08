Test elixir plugin hooks using fixture projects in `plugins/elixir/test/integration/fixtures/`.

## Fixtures

| Fixture | Dependencies | Purpose |
|---------|--------------|---------|
| basic-project | none | Format + compile only |
| credo-project | credo | Credo analysis |
| full-project | credo, dialyxir, ex_doc, sobelow | All checks |

Setup fixtures if deps/ missing: `(cd fixture && mix deps.get)`

## What to Verify

### Post-Edit Hook
Edit files and verify the hook:
- Reports compilation errors when code has syntax issues
- Reports credo issues when dependency present
- Auto-formats code after edits
- Reports sobelow findings for security issues

### Pre-Commit Hook
Attempt commits and verify the hook blocks when:
- Code has compilation errors
- Code is unformatted
- Credo strict mode fails
- Other checks fail based on dependencies

## Success Criteria

Each capability should trigger appropriate feedback. Report results as pass/fail table.
