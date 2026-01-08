Test elixir plugin hooks by walking through fixture projects in `test/integration/fixtures/`.

## Execution Approach

**Walk through each test scenario manually in the main conversation** so hook responses are visible in real-time via system-reminders.

1. Use TodoWrite to track progress through test scenarios
2. For each test: edit a file or run a command, observe the hook response
3. Restore files to original state after each test
4. Report final results as a table

## Fixtures

| Fixture | Dependencies | Purpose |
|---------|--------------|---------|
| basic-project | none | Format + compile only |
| credo-project | credo | Credo analysis |
| full-project | credo, dialyxir, ex_doc, sobelow, mix_audit + test/ | Most checks |
| ash-project | ash | Ash codegen checks |
| precommit-project | none (has precommit alias) | Precommit alias deferral |
| unused-deps-project | jason (unused) | Unused deps check |

Setup if deps/ missing: `(cd fixture && mix deps.get)`

## Test Scenarios

### Post-Edit Hook (5 capabilities)

1. **Format** (basic-project)
   - Edit `lib/example.ex` with bad formatting (e.g., `def foo,do: :bar`)
   - Expected: File is auto-formatted (comma gets space)

2. **Compile Error Detection** (basic-project)
   - Edit `lib/example.ex` to introduce syntax error (e.g., `def broken(`)
   - Expected: Hook reports `[COMPILE ERROR]` in system-reminder

3. **Credo** (credo-project)
   - Edit file to add serious credo issue ([F|W|C|R] not [D])
   - Expected: Hook reports `[CREDO]` if issue is serious
   - Note: Post-edit filters to serious issues only, not design [D]

4. **Ash Codegen** (ash-project)
   - Edit `lib/example.ex` to add new attribute
   - Expected: Hook reports `[ASH CODEGEN]` if codegen needed

5. **Sobelow** (full-project)
   - Edit file to introduce security issue (e.g., hardcoded secret)
   - Expected: Hook reports `[SOBELOW SECURITY]` for high/medium findings

### Pre-Commit Hook (11 capabilities)

6. **Precommit Alias** (precommit-project)
   - Make code unformatted, attempt git commit
   - Expected: Hook defers to `mix precommit` and blocks on failure

7. **Format Check** (basic-project)
   - Make code unformatted, attempt commit
   - Expected: Hook blocks with `[FORMAT]`

8. **Compile Check** (basic-project)
   - Introduce compile error, attempt commit
   - Expected: Hook blocks with `[COMPILE]`

9. **Unused Deps** (unused-deps-project)
   - Attempt commit (jason dep is unused)
   - Expected: Hook blocks with `[DEPS]`

10. **Credo Strict** (credo-project)
    - Introduce any credo issue, attempt commit
    - Expected: Hook blocks with `[CREDO]` (uses --strict mode)

11. **Ash Codegen** (ash-project)
    - Make Ash codegen out of sync, attempt commit
    - Expected: Hook blocks with `[ASH CODEGEN]`

12. **Dialyzer** (full-project)
    - Introduce type error, attempt commit
    - Expected: Hook blocks with `[DIALYZER]`

13. **ExDoc** (full-project)
    - Introduce doc warning, attempt commit
    - Expected: Hook blocks with `[EXDOC]`

14. **ExUnit** (full-project)
    - Create failing test in test/, attempt commit
    - Expected: Hook blocks with `[TESTS]`

15. **Mix Audit** (full-project)
    - Have vulnerable dependency, attempt commit
    - Expected: Hook blocks with `[SECURITY AUDIT]`

16. **Sobelow** (full-project)
    - Introduce security issue, attempt commit
    - Expected: Hook blocks with `[SOBELOW]`

## Results Format

| # | Test | Fixture | Status | Evidence |
|---|------|---------|--------|----------|
| 1 | Format | basic-project | PASS/FAIL | ... |
| 2 | Compile Error | basic-project | PASS/FAIL | ... |
| ... | ... | ... | ... | ... |

## Important Notes

- Hook responses appear as `<system-reminder>` after Edit tool calls
- Pre-commit blocking appears as tool use error when Bash is denied
- Always restore files to original state after each test
