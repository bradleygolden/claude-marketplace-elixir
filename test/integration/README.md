# Integration Tests

Integration tests for elixir plugin hooks using real Mix projects.

## Fixtures

| Fixture | Dependencies | Purpose |
|---------|--------------|---------|
| basic-project | none | Format + compile only |
| credo-project | credo | Credo analysis |
| full-project | credo, dialyxir, ex_doc, sobelow | All checks |

## Setup

Run `mix deps.get` in each fixture:

```bash
for dir in fixtures/*/; do
  (cd "$dir" && mix deps.get)
done
```

## Running Tests

Use the `/integration-test` command in Claude Code with the elixir plugin installed.
