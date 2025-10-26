---
description: Execute Elixir implementation plan with verification checkpoints
argument-hint: [plan-name or path]
allowed-tools: Read, Write, Edit, Grep, Glob, Task, Bash, TodoWrite, AskUserQuestion
---

# Implement

Execute an approved Elixir implementation plan with built-in verification and progress tracking.

## Purpose

Follow implementation plans phase-by-phase while maintaining quality through automated verification at each checkpoint.

## Steps to Execute:

### Step 1: Locate and Read Plan

**If user provides plan name:**
```bash
# Search for plan file
find {{DOCS_LOCATION}}/plans -name "*[plan-name]*.md" -type f
```

**If user provides path:**
- Read the file directly

**If no argument provided:**
- List available plans:
```bash
ls -t {{DOCS_LOCATION}}/plans/*.md | head -5
```
- Ask user which plan to implement

**Read plan completely:**
- Use Read tool WITHOUT limit/offset
- Parse the full plan structure
- Identify all phases/tasks/milestones
- Note the success criteria

### Step 2: Check Existing Progress

**Look for checkmarks in the plan:**
- Identify which phases/tasks are already completed (checked)
- Identify current phase/task (first unchecked item)
- Verify completed items are actually done (spot check)

**If resuming work:**
- Trust completed checkmarks unless evidence suggests otherwise
- Start from first unchecked phase/task
- Confirm with user if multiple checkmarks exist but work seems incomplete

**If starting fresh:**
- All items should be unchecked
- Begin with Phase 1 / Task 1 / Milestone 1

### Step 3: Review Original Context

**Before implementing, review:**
- Original research that informed the plan
- Related tickets or documentation
- Files that will be modified

**Read referenced files:**
- Read any files mentioned in the current phase/task
- Understand current implementation
- Identify exact changes needed

### Step 4: Execute Phase-by-Phase

**For each phase/task/milestone:**

1. **Mark as in-progress** in TodoWrite
   ```
   1. [in_progress] Implementing Phase 1: Database Layer
   2. [pending] Implementing Phase 2: Context Functions
   3. [pending] Implementing Phase 3: Web Layer
   ```

2. **Follow the plan's core intent** while remaining flexible:
   - Stick to the planned approach
   - Use the code examples as guides
   - Adapt if you discover better patterns in the codebase
   - If reality diverges from plan, surface the discrepancy (see Mismatches section)

3. **Make the changes:**
   - Create new modules as specified
   - Modify existing modules as specified
   - Add tests as specified
   - Update configuration if needed

4. **Run verification** after completing the phase:
   {{VERIFICATION_COMMANDS}}

5. **Update the plan file** with checkmarks:
   - Use Edit tool to add `[x]` to completed items in the plan
   - Example: Change `- [ ] Create schema` to `- [x] Create schema`

6. **Pause for confirmation:**
   - Present verification results
   - Show what was completed
   - Show test output if relevant
   - Ask: "Phase N complete. Proceed to Phase N+1?"
   - Wait for user approval before continuing

### Step 5: Handle Plan vs Reality Mismatches

**When reality diverges from the plan:**

**State the discrepancy explicitly:**
- "The plan expects X to exist at path/to/file.ex:10"
- "But I found Y instead"
- "This matters because Z"

**Explain why it matters:**
- How does this affect the current phase?
- Can we proceed or must we adjust?

**Request clarity:**
- "Should I:"
  - "A) Adapt the plan to match reality"
  - "B) Update reality to match the plan"
  - "C) Something else"

**Do not guess** - always surface mismatches and get user input.

### Step 6: Complete Implementation

**After all phases/tasks complete:**

1. **Run full verification suite:**
   {{FULL_VERIFICATION_SUITE}}

2. **Mark plan as complete:**
   - Edit plan file frontmatter: `status: completed`
   - Add completion date to frontmatter

3. **Present final summary:**
   ```markdown
   ✅ Implementation Complete: [Plan Name]

   **Phases Completed**: [N]
   **Files Modified**: [list key files]
   **Tests Added**: [N]

   **Final Verification**:
   - ✅ Compilation: Success
   - ✅ Tests: [N] passed
   {{QUALITY_TOOLS_SUMMARY}}

   **Next Steps**:
   - Run QA validation: `/qa "[plan-name]"`
   - Manual testing recommended
   - Ready for code review
   ```

## Verification Commands

### Per-Phase Verification

After each phase, run:

```bash
# Compile with warnings as errors
mix compile --warnings-as-errors

# Run tests
{{TEST_COMMAND}}

# Format check
mix format --check-formatted
```

{{OPTIONAL_QUALITY_CHECKS}}

### Full Verification Suite

After completing all phases:

```bash
# Clean compile
mix clean && mix compile --warnings-as-errors

# Full test suite
{{TEST_COMMAND}}

# Format check
mix format --check-formatted

{{FULL_QUALITY_SUITE}}
```

## Handling Failures

### If Compilation Fails

1. **Show the error**
2. **Identify the issue** (missing import, typo, etc.)
3. **Fix the issue**
4. **Re-run compilation**
5. **Do not proceed** until compilation succeeds

### If Tests Fail

1. **Show the test output**
2. **Analyze the failure**:
   - Is it expected based on incomplete implementation?
   - Is it a real bug in the new code?
   - Is it a pre-existing test that needs updating?
3. **Fix or update as needed**
4. **Re-run tests**
5. **Do not proceed** until tests pass

### If Pre-Commit Hook Triggers

Some projects have pre-commit hooks (format, Credo, etc.):

1. **Read the hook output**
2. **Apply automatic fixes** if available:
   ```bash
   mix format
   ```
3. **Address issues** manually if needed
4. **Re-run verification**

## Progress Tracking

### TodoWrite Usage

Maintain a todo list throughout implementation:

```
1. [completed] Read and parse plan
2. [completed] Phase 1: Database Layer
3. [in_progress] Phase 2: Context Functions
4. [pending] Phase 3: Web Layer
5. [pending] Phase 4: Tests
6. [pending] Final verification
```

**Update frequently:**
- Mark completed when phase finishes
- Mark in-progress when starting new phase
- Keep user informed of progress

### Plan File Updates

The plan file is the source of truth:

- **Add checkmarks** as phases complete
- **Update status** in frontmatter
- **Add notes** if implementation deviates
- **Preserve history** (don't delete content)

## Flexibility vs Adherence

### Stick to the Plan When:
- Code examples are clear and correct
- Planned approach matches codebase patterns
- No new information contradicts the plan

### Adapt When:
- You discover better existing patterns
- File structure has changed
- Dependencies have been updated
- Tests reveal issues with planned approach

### Always Surface When:
- Plan expects something that doesn't exist
- Existing code contradicts planned changes
- Uncertainty about how to proceed

## Elixir-Specific Guidelines

### Module Creation

When creating new modules:

```elixir
defmodule MyApp.Context.Feature do
  @moduledoc """
  [Description of module purpose]
  """

  # Clear module structure
  # Use statements at top
  # Group related functions
  # Add @doc for public functions
end
```

### Test Organization

```elixir
defmodule MyApp.FeatureTest do
  use MyApp.DataCase  # or ConnCase for controllers

  describe "function_name/1" do
    test "success case" do
      # Arrange
      # Act
      # Assert
    end

    test "error case" do
      # Test error handling
    end
  end
end
```

### Migration Files

When creating migrations:

```elixir
defmodule MyApp.Repo.Migrations.CreateFeature do
  use Ecto.Migration

  def change do
    create table(:features) do
      add :name, :string, null: false
      # ...

      timestamps()
    end

    # Indexes
    create index(:features, [:name])
  end
end
```

**Run migration after creation:**
```bash
mix ecto.migrate
```

## Resume Capability

### If Implementation is Interrupted

The plan file preserves state:

1. **Read the plan** - checkmarks show progress
2. **Verify checkmarks** - spot check completed work
3. **Continue** from first unchecked item
4. **No need to restart** - trust the checkmarks

### If Tests Break Later

Sometimes completed phases have tests that break:

1. **Identify which phase's tests broke**
2. **Analyze the root cause**
3. **Fix the issue**
4. **Re-verify that phase**
5. **Continue with current phase**

## Example Session

**User**: `/implement user-authentication`

**Process**:
1. Find plan: `{{DOCS_LOCATION}}/plans/2025-01-23-user-authentication.md`
2. Read plan: 4 phases, all unchecked
3. Phase 1: Create User schema
   - Create `lib/my_app/accounts/user.ex`
   - Create migration
   - Run `mix ecto.migrate`
   - Verify: `mix compile && {{TEST_COMMAND}}`
   - Update plan: `[x] Phase 1: Database Layer`
   - Pause: "Phase 1 complete. Proceed to Phase 2?"
4. User: "yes"
5. Phase 2: Add context functions
   - Implement in `lib/my_app/accounts.ex`
   - Add tests
   - Verify: `mix compile && {{TEST_COMMAND}}`
   - Update plan: `[x] Phase 2: Context Functions`
   - Pause: "Phase 2 complete. Proceed to Phase 3?"
6. Continue until all phases complete
7. Final verification suite
8. Mark plan status: completed
9. Present summary

## Important Reminders

- **One phase at a time**: Complete and verify before moving on
- **Checkpoints matter**: Don't skip verification
- **Update the plan**: Keep checkmarks current
- **Pause for confirmation**: Let user track progress
- **Surface mismatches**: Don't guess when plan diverges from reality
- **Trust completions**: Checkmarks indicate done work (unless evidence suggests otherwise)
- **Maintain quality**: All verifications must pass
