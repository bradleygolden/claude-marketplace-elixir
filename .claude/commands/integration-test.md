Test elixir plugin post-edit hooks by walking through fixture projects in `test/integration/fixtures/`.

## Execution Approach

**Walk through each test scenario manually in the main conversation** so hook responses are visible in real-time via system-reminders.

1. Use TodoWrite to track progress through test scenarios
2. For each test: edit a file, observe the hook response
3. Restore files to original state after each test
4. Report final results as a table

## Fixtures

| Fixture | Dependencies | Purpose |
|---------|--------------|---------|
| basic-project | none | Format + compile |
| credo-project | credo | Credo analysis |
| ash-project | ash, ash_postgres | Ash codegen |
| full-project | credo, dialyxir, ex_doc, sobelow, mix_audit | Sobelow security |

Setup if deps/ missing: `(cd fixture && mix deps.get)`

## Test Scenarios (Post-Edit Hook)

1. **Format** (basic-project)
   - Edit `lib/example.ex` with bad formatting (e.g., `def foo,do: :bar`)
   - Expected: File is auto-formatted (comma gets space)

2. **Compile Error Detection** (basic-project)
   - Edit `lib/example.ex` to introduce syntax error (e.g., `def broken(`)
   - Expected: Hook reports `[COMPILE ERROR]` in system-reminder

3. **Credo** (credo-project)
   - Edit file to add warning-level issue (e.g., `IO.inspect(:debug)`)
   - Expected: Hook reports `[CREDO]` with warning
   - Note: Post-edit filters to serious issues only ([F|W|C|R] not [D])

4. **Ash Codegen** (ash-project)
   - Edit `lib/example.ex` to add new attribute (e.g., `attribute(:age, :integer, public?: true)`)
   - Expected: Hook reports `[ASH CODEGEN]` pending code generation

5. **Sobelow** (full-project)
   - Edit file to introduce SQL injection (e.g., `Ecto.Adapters.SQL.query(conn, "SELECT * FROM users WHERE id = #{id}")`)
   - Expected: Hook reports Sobelow findings in JSON format

## Results Format

| # | Test | Fixture | Status | Evidence |
|---|------|---------|--------|----------|
| 1 | Format | basic-project | PASS/FAIL | ... |
| 2 | Compile Error | basic-project | PASS/FAIL | ... |
| 3 | Credo | credo-project | PASS/FAIL | ... |
| 4 | Ash Codegen | ash-project | PASS/FAIL | ... |
| 5 | Sobelow | full-project | PASS/FAIL | ... |

## Notes

- Hook responses appear as `<system-reminder>` after Edit/Write tool calls
- Pre-commit hooks (PreToolUse) require the plugin to be installed and cannot be tested this way
- Always restore files to original state after each test
