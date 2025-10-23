# Credo Plugin Test Suite

This test suite validates the credo@elixir plugin hooks using pre-canned test projects.

**Prerequisite**: The credo@elixir plugin must be installed before running this test.

## Test Structure

Pre-canned projects are located in:
- `test/credo/postedit-test/` - Tests PostToolUse hook (provides Credo context)
- `test/credo/precommit-test/` - Tests PreToolUse hook (runs Credo before commits)

## Setup

Both test projects require Credo dependencies to be installed:

```bash
cd test/credo/postedit-test && mix deps.get
cd test/credo/precommit-test && mix deps.get
```

---

## Test 1: PostToolUse Hook (Non-blocking)

### Test Steps

1. Use the Read tool to view `test/credo/postedit-test/lib/code_with_credo_issues.ex` and observe the existing Credo violations:
   - Missing `@moduledoc`
   - CamelCase function names (should be snake_case)
   - Lines exceeding 120 characters
   - TODO comments
   - Deep nesting

2. Use the Edit tool to make ANY change to `test/credo/postedit-test/lib/code_with_credo_issues.ex` (e.g., add a new function, modify existing code).

3. Observe the PostToolUse hook providing Credo analysis in the `additionalContext` system reminder.

4. The context should show Credo violations like:
   - `Readability.ModuleDoc` - Missing moduledoc
   - `Naming.FunctionName` - CamelCase function names
   - `Refactor.Nesting` - Deep nesting issues
   - `Design.TagTODO` - TODO comments

### Expected Behavior

The PostToolUse hook should:
- Execute `mix credo` on the edited file
- Provide Credo violations as context in system reminders
- Be NON-BLOCKING (edit succeeds even with violations)
- Help you understand code quality issues without preventing edits

**Success criteria**: Hook provides Credo violation feedback after file edit without blocking.

---

## Test 2: PreToolUse Hook (Non-blocking)

### Test Steps

1. Use the Read tool to view `test/credo/precommit-test/lib/code_with_issues.ex` and observe the Credo violations:
   - Missing `@moduledoc`
   - CamelCase function name (`ProcessData` should be `process_data`)
   - FIXME comments
   - Lines exceeding 120 characters
   - Deep nesting (5+ levels)

2. Try to commit:
```bash
cd test/credo/precommit-test && git add . && git commit -m "Test commit"
```

3. Observe that the PreToolUse hook runs `mix credo --strict` before the commit.

4. The Credo output should appear showing all violations.

5. The commit should PROCEED (Credo hook is informational, not blocking).

### Expected Behavior

The PreToolUse hook should:
- Execute `mix credo --strict` before git commits
- Display Credo violations in the transcript
- Be NON-BLOCKING (commit succeeds even with violations)
- Provide visibility into code quality issues before committing

**Success criteria**: Hook runs Credo check before git commit and displays output without blocking.

---

## Credo Violations vs Compilation Errors

**Important**: Credo checks CODE QUALITY, not correctness:

**Credo Issues** (style/readability):
- Missing moduledocs
- Function naming conventions (snake_case vs CamelCase)
- Line length (>120 chars)
- TODO/FIXME comments
- Code complexity (nesting depth, function length)

**NOT Credo Issues** (these are compiler warnings/errors):
- Unused variables
- Undefined functions
- Type errors
- Syntax errors

---

## Summary Format

After completing all tests, provide a summary:

```
✅/❌ PostToolUse hook - Did it provide Credo context after editing?
✅/❌ PreToolUse hook - Did it run Credo before git commit?

Overall result: PASS/FAIL
```
