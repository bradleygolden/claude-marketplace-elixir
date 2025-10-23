# Core Plugin Test Suite

This test suite validates the core@elixir plugin hooks using pre-canned test projects.

**Prerequisite**: The core@elixir plugin must be installed before running this test.

## Test Structure

Pre-canned projects are located in:
- `test/core/autoformat-test/` - Tests auto-format hook
- `test/core/compile-test/` - Tests compile check hook
- `test/core/precommit-test/` - Tests pre-commit hook

## Test 1: Auto-format Hook (PostToolUse - Non-blocking)

### Test Steps

1. Use the Read tool to view `test/core/autoformat-test/lib/badly_formatted.ex` and note the unformatted code.

2. Use the Write or Edit tool to modify `test/core/autoformat-test/lib/badly_formatted.ex` (make any change - add a comment, modify a function).

3. Use the Read tool again to verify the file was automatically formatted.

### Expected Behavior

The auto-format hook should automatically format the file with proper spacing and indentation after ANY edit.

**Success criteria**: File is properly formatted after editing, regardless of what changes were made.

---

## Test 2: Compile Check Hook (PostToolUse - Blocking)

### Test Steps

1. Use the Read tool to view `test/core/compile-test/lib/broken_code.ex` and observe the existing compilation errors.

2. Use the Edit tool to make ANY change to `test/core/compile-test/lib/broken_code.ex` (e.g., add a comment).

3. Observe that the compile check hook BLOCKS and reports compilation errors in the system reminders.

4. Use the Edit tool to fix the compilation errors (replace undefined variables/functions with valid code like `:ok`).

5. Observe that the compile check hook now allows the edit to proceed.

### Expected Behavior

- The compile check hook should BLOCK any edit to a file with compilation errors
- After fixing errors, the hook should allow edits through
- Hook runs `mix compile --warnings-as-errors` from the project root

**Success criteria**: Hook blocks edits when compilation fails and allows edits when compilation succeeds.

---

## Test 3: Pre-commit Hook (PreToolUse - Blocking)

**Important**: This test uses bash commands (not Write/Edit tools) to modify files to bypass the PostToolUse hooks.

### Test Steps

1. Use the Read tool to view both files in `test/core/precommit-test/lib/`:
   - `unformatted.ex` - Has formatting issues
   - `compilation_error.ex` - Has compilation errors

2. Try to commit without fixing the issues:
```bash
cd test/core/precommit-test && git add . && git commit -m "Test commit"
```

3. Observe that the pre-commit hook BLOCKS the commit and reports BOTH issues:
   - Formatting errors from `mix format --check-formatted`
   - Compilation errors from `mix compile --warnings-as-errors`

4. Fix the formatting using bash (bypasses hooks):
```bash
cd test/core/precommit-test && mix format
```

5. Fix the compilation errors using the Edit tool:
   - Edit `test/core/precommit-test/lib/compilation_error.ex`
   - Replace undefined variables/functions with valid code

6. Try to commit again:
```bash
cd test/core/precommit-test && git add . && git commit -m "Fixed commit"
```

7. Observe that the commit now succeeds.

### Expected Behavior

- First commit attempt should BLOCK with context showing:
  - Which files are not formatted
  - Which files have compilation errors
- After fixing BOTH issues, commit should succeed
- Hook validates: formatting, compilation, and unused dependencies

**Success criteria**: Hook blocks commits when validation fails and allows commits when all checks pass.

---

## Summary Format

After completing all tests, provide a summary:

```
✅/❌ Auto-format hook (non-blocking) - Did it format the file after editing?
✅/❌ Compile check hook (blocking) - Did it block edits to broken code?
✅/❌ Pre-commit hook (blocking) - Did it block commits and show BOTH formatting and compilation issues?

Overall result: PASS/FAIL
```
