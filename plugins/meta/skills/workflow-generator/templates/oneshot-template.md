---
description: Execute complete workflow from research to QA in one command
argument-hint: "[feature-description]"
allowed-tools: SlashCommand, TodoWrite, Bash, Read, AskUserQuestion
---

# Oneshot Workflow

Execute the complete workflow cycle (research → plan → implement → qa) for a single feature in one command.

## Purpose

This command automates the entire development workflow:
1. Research existing codebase patterns
2. Create detailed implementation plan
3. Execute the plan with verification
4. Validate implementation quality

## Usage

```bash
/oneshot "Add user profile page with avatar upload"
/oneshot "Refactor authentication to use OAuth"
```

## Execution Flow

When invoked with a feature description, this command will:

### Step 1: Initialize

Create TodoWrite plan to track the entire workflow:

```
1. [in_progress] Parse feature description and setup
2. [pending] Research phase - understand existing patterns
3. [pending] Planning phase - create implementation plan
4. [pending] Implementation phase - execute the plan
5. [pending] QA phase - validate implementation
6. [pending] Present final summary
```

### Step 2: Research Phase

Execute research to understand the codebase:

```
SlashCommand(command="/research $ARGUMENTS")
```

**What happens:**
- Spawns parallel agents to find relevant patterns
- Documents existing implementations
- Saves research document to `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`

**Wait for research to complete** before proceeding.

Mark step 2 completed, mark step 3 in_progress.

### Step 3: Planning Phase

Create implementation plan based on research:

```
SlashCommand(command="/plan $ARGUMENTS")
```

**What happens:**
- Uses research findings as context
- Asks design questions if needed
- Creates phased implementation plan
- Defines success criteria (automated + manual)
- Saves plan to `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`

**Wait for planning to complete** before proceeding.

**Capture the plan filename** from the output (needed for next steps).

Mark step 3 completed, mark step 4 in_progress.

### Step 4: Implementation Phase

Execute the plan:

```
SlashCommand(command="/implement PLAN_FILENAME")
```

Where `PLAN_FILENAME` is extracted from the plan command output (e.g., "2025-10-25-user-profile").

**What happens:**
- Reads the plan document
- Executes phase by phase
- Runs verification after each phase:
  - `mix compile --warnings-as-errors`
  - `{{TEST_COMMAND}}`
  - `mix format --check-formatted`
  {{#if QUALITY_TOOLS}}
  - Quality tools: {{QUALITY_TOOLS_SUMMARY}}
  {{/if}}
- Updates checkmarks in plan
- Handles mismatches between plan and reality

**Wait for implementation to complete** before proceeding.

Mark step 4 completed, mark step 5 in_progress.

### Step 5: QA Phase

Validate the implementation:

```
SlashCommand(command="/qa PLAN_FILENAME")
```

**What happens:**
- Runs all quality gate checks
- Spawns validation agents
- Generates comprehensive QA report
- Validates against plan success criteria
- Provides actionable feedback

**Wait for QA to complete** before proceeding.

**After QA completes, check for critical issues:**

**5.1 Read QA Report and Parse Status**

Find and read the most recent QA report:
```bash
ls -t {{DOCS_LOCATION}}/qa-reports/*-qa.md 2>/dev/null | head -1
```

Read the QA report file and parse the "Overall Status" from the Executive Summary section.

Possible statuses:
- ✅ ALL PASS or ✅ PASS
- ⚠️ NEEDS ATTENTION or ⚠️ PASS WITH WARNINGS
- ❌ CRITICAL ISSUES or ❌ FAIL

**5.2 Handle QA Results Conditionally**

**IF status is ❌ CRITICAL ISSUES or ❌ FAIL:**

  **5.2.1 Extract Critical Issue Count**

  Parse the QA report to count critical issues listed.

  **5.2.2 Prompt User for Auto-Fix**

  Use AskUserQuestion tool:
  ```
  Question: "QA detected [N] critical issues. Generate and execute fix plan automatically?"
  Header: "Auto-Fix"
  Options (multiSelect: false):
    Option 1:
      Label: "Yes, auto-fix and re-validate"
      Description: "Automatically create fix plan, implement fixes, and re-run QA"
    Option 2:
      Label: "No, stop for manual fixes"
      Description: "Stop oneshot workflow, fix manually, then re-run /qa"
  ```

  **5.2.3 If User Selects "Yes, auto-fix and re-validate":**

  Report: "Generating fix plan for [N] critical issues..."

  Add dynamic todos to track fix cycle:
  ```
  TodoWrite: Add new todos:
  5a. [in_progress] Generate fix plan for critical issues
  5b. [pending] Execute fix implementation
  5c. [pending] Re-run QA validation
  ```

  Mark step 5a in_progress.

  **Get QA Report Path:**
  ```bash
  ls -t {{DOCS_LOCATION}}/qa-reports/*-qa.md 2>/dev/null | head -1
  ```

  **Generate Fix Plan:**
  ```
  SlashCommand(command="/plan Fix critical issues from QA report: [QA_REPORT_PATH]")
  ```

  Wait for plan generation to complete.

  **Extract fix plan filename** from output (e.g., "plan-2025-10-27-fix-*").
  Store plan name without path/extension in variable: FIX_PLAN_NAME

  Report: "Fix plan created at: {{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]"

  Mark step 5a completed, mark step 5b in_progress.

  **Execute Fix Implementation:**
  ```
  SlashCommand(command="/implement [FIX_PLAN_NAME]")
  ```

  Wait for implementation to complete.

  Report: "Fixes applied. Re-running QA..."

  Mark step 5b completed, mark step 5c in_progress.

  **Re-run QA Validation:**
  ```
  SlashCommand(command="/qa PLAN_FILENAME")
  ```

  Note: Use original PLAN_FILENAME, not the fix plan name.

  Wait for QA to complete.

  **Read New QA Report:**
  ```bash
  ls -t {{DOCS_LOCATION}}/qa-reports/*-qa.md 2>/dev/null | head -1
  ```

  Parse new status from report.

  **Evaluate Re-validation Results:**

  IF new status is ✅ ALL PASS or ✅ PASS:
    Report: "✅ Auto-fix successful! QA passed after fixes."
    Mark step 5c completed with note: "Passed after auto-fix"
    Mark step 5 completed with note: "Completed with auto-fix"
    Mark step 6 in_progress
    Set workflow_status = "SUCCESS_WITH_AUTOFIX"
    Continue to Step 6

  ELSE IF new status is ⚠️ NEEDS ATTENTION or ⚠️ PASS WITH WARNINGS:
    Report: "⚠️ Auto-fix partially successful. QA passed with warnings."
    Mark step 5c completed with note: "Passed with warnings after auto-fix"
    Mark step 5 completed with note: "Completed with warnings after auto-fix"
    Mark step 6 in_progress
    Set workflow_status = "SUCCESS_WITH_WARNINGS_AFTER_AUTOFIX"
    Continue to Step 6

  ELSE IF new status is ❌ CRITICAL ISSUES or ❌ FAIL:
    Report: "❌ Auto-fix incomplete. Critical issues remain."
    Report: "Fix plan: {{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]"
    Report: "Final QA report: [NEW_QA_REPORT_PATH]"
    Report: "Manual intervention required. Review reports and fix remaining issues."
    Mark step 5c completed with note: "Failed after auto-fix attempt"
    Mark step 5 completed with note: "Failed - auto-fix incomplete"
    Mark step 6 in_progress
    Set workflow_status = "FAILED_AUTOFIX_INCOMPLETE"
    Continue to Step 6 (summary will show failure details)

  **5.2.4 If User Selects "No, stop for manual fixes":**

  Report: "Workflow stopped for manual fixes."
  Report: "QA report: [QA_REPORT_PATH]"
  Report: "After fixing, continue with: /qa PLAN_FILENAME"

  Mark step 5 completed with note: "Stopped for manual fixes"
  Mark step 6 in_progress
  Set workflow_status = "PAUSED_MANUAL_FIXES_REQUIRED"
  Continue to Step 6 (summary will show paused status)

**ELSE IF status is ⚠️ NEEDS ATTENTION or ⚠️ PASS WITH WARNINGS:**

  Report: "QA passed with warnings (non-blocking)"
  Mark step 5 completed with note: "Passed with warnings"
  Mark step 6 in_progress
  Set workflow_status = "SUCCESS_WITH_WARNINGS"
  Continue to Step 6

**ELSE IF status is ✅ ALL PASS or ✅ PASS:**

  Report: "QA passed successfully"
  Mark step 5 completed
  Mark step 6 in_progress
  Set workflow_status = "SUCCESS"
  Continue to Step 6

### Step 6: Final Summary

Present comprehensive workflow summary based on workflow_status:

**IF workflow_status is "SUCCESS":**

```markdown
# ✅ Oneshot Workflow Complete - Success

**Feature**: [Feature Description]
**Status**: ✅ SUCCESS

## Phases Executed

1. ✅ Research - Codebase patterns analyzed
2. ✅ Planning - Implementation plan created
3. ✅ Implementation - All phases completed
4. ✅ QA Validation - All quality gates passed

## Final QA Status

✅ ALL PASS - All quality gates passed

**Automated Checks**:
- Compilation: ✅
- Tests: ✅ [N/M passed]
- Formatting: ✅
{{#if QUALITY_TOOLS}}
- Quality tools: {{QUALITY_TOOLS_STATUS}}
{{/if}}

**Code Quality**:
- Code review: No issues
- Test coverage: Adequate
- Documentation: Complete

## Next Steps

Your implementation is ready!

1. **Review changes**: `git diff`
2. **Create commit**:
   ```bash
   git add -A
   git commit -m "[Feature description]"
   ```
3. **Push**: `git push origin $(git branch --show-current)`

## Documentation

- **Research**: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`
- **Plan**: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`
- **QA Report**: `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
```

**IF workflow_status is "SUCCESS_WITH_AUTOFIX":**

```markdown
# ✅ Oneshot Workflow Complete - Success (with Auto-Fix)

**Feature**: [Feature Description]
**Status**: ✅ SUCCESS (auto-fixes applied)

## Phases Executed

1. ✅ Research - Codebase patterns analyzed
2. ✅ Planning - Implementation plan created
3. ✅ Implementation - All phases completed
4. ⚠️ QA Validation (initial) - Critical issues detected
5. ✅ Fix Plan Generation - Issues analyzed and fix plan created
6. ✅ Fix Implementation - Automated fixes applied
7. ✅ QA Re-validation - All quality gates passed

## Fix Details

**Initial QA**: ❌ FAILED ([N] critical issues)
**Fix Plan**: `{{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]`
**Fix Result**: ✅ All issues resolved
**Final QA**: ✅ ALL PASS

**Issues Fixed**:
[List top 3-5 issues that were fixed automatically]

## Next Steps

Your implementation is ready (with auto-fixes applied)!

1. **Review changes including fixes**: `git diff`
2. **Review fix plan**: `cat {{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]`
3. **Create commit**:
   ```bash
   git add -A
   git commit -m "[Feature description]"
   ```
4. **Push**: `git push origin $(git branch --show-current)`

## Documentation

- **Research**: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`
- **Plan**: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`
- **Fix Plan**: `{{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]`
- **QA Report**: `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
```

**IF workflow_status is "SUCCESS_WITH_WARNINGS" or "SUCCESS_WITH_WARNINGS_AFTER_AUTOFIX":**

```markdown
# ⚠️ Oneshot Workflow Complete - Success with Warnings

**Feature**: [Feature Description]
**Status**: ⚠️ SUCCESS WITH WARNINGS

## Phases Executed

1. ✅ Research
2. ✅ Planning
3. ✅ Implementation
4. ⚠️ QA Validation - Passed with warnings
{{#if workflow_status equals "SUCCESS_WITH_WARNINGS_AFTER_AUTOFIX"}}
5. ✅ Fix Plan Generation (for critical issues)
6. ✅ Fix Implementation
7. ⚠️ QA Re-validation - Passed with warnings
{{/if}}

## QA Status

⚠️ PASS WITH WARNINGS - Core functionality validated, warnings present

**Warnings**:
[List warnings from QA report]

## Next Steps

Implementation complete, but review warnings:

1. **Review warnings**: `cat {{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
2. **Address warnings** (optional but recommended)
3. **Review changes**: `git diff`
4. **Create commit**:
   ```bash
   git add -A
   git commit -m "[Feature description]"
   ```

## Documentation

- **Research**: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`
- **Plan**: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`
{{#if workflow_status equals "SUCCESS_WITH_WARNINGS_AFTER_AUTOFIX"}}
- **Fix Plan**: `{{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]`
{{/if}}
- **QA Report**: `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
```

**IF workflow_status is "PAUSED_MANUAL_FIXES_REQUIRED":**

```markdown
# ⚠️ Oneshot Workflow Paused - Manual Fixes Required

**Feature**: [Feature Description]
**Status**: ⚠️ PAUSED

## Phases Executed

1. ✅ Research
2. ✅ Planning
3. ✅ Implementation
4. ❌ QA Validation - Failed with critical issues

## QA Failure Details

**Status**: ❌ CRITICAL ISSUES ([N] issues found)
**QA Report**: `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`

**Critical Issues**:
[List top 3-5 critical issues from report]

## Next Steps

Workflow paused for manual fixes:

1. **Review QA report**: `cat {{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
2. **Fix critical issues manually**
3. **Re-run QA**: `/qa [PLAN_NAME]`
4. **Or generate fix plan**: `/qa` (will offer fix plan generation)

## Documentation

- **Research**: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`
- **Plan**: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`
- **QA Report**: `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
```

**IF workflow_status is "FAILED_AUTOFIX_INCOMPLETE":**

```markdown
# ❌ Oneshot Workflow Failed - Auto-Fix Incomplete

**Feature**: [Feature Description]
**Status**: ❌ FAILED (auto-fix incomplete)

## Phases Executed

1. ✅ Research
2. ✅ Planning
3. ✅ Implementation
4. ❌ QA Validation (initial) - Failed with critical issues
5. ✅ Fix Plan Generation - Fix strategy created
6. ✅ Fix Implementation - Fixes attempted
7. ❌ QA Re-validation - Still failing

## Fix Attempt Details

**Initial Issues**: [N] critical issues
**Fix Plan**: `{{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]`
**Fixes Applied**: [M] fixes attempted
**Remaining Issues**: [P] critical issues remain

**Remaining Critical Issues**:
[List remaining issues from final QA report]

## Next Steps

Auto-fix was incomplete, manual intervention required:

1. **Review final QA report**: `cat {{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
2. **Review fix plan**: `cat {{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]`
3. **Fix remaining issues manually**
4. **Re-run QA**: `/qa [ORIGINAL_PLAN_NAME]`
5. **Or generate new fix plan**: `/qa` (will offer new plan generation)

## Documentation

- **Research**: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`
- **Plan**: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`
- **Fix Plan**: `{{DOCS_LOCATION}}/plans/[FIX_PLAN_FILENAME]`
- **QA Report** (initial): `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md`
- **QA Report** (after fix): `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-qa.md` (most recent)
```

Mark step 6 completed.

## Error Handling

### Research Phase Fails

If `/research` fails or times out:
1. Report the error to user
2. Ask if they want to:
   - Retry research
   - Skip research and proceed with planning
   - Abort oneshot workflow

### Planning Phase Fails

If `/plan` fails:
1. Report the error
2. Research document still exists for reference
3. Ask if they want to:
   - Retry planning
   - Manually create plan
   - Abort workflow

### Implementation Phase Fails

If `/implement` fails or verification fails:
1. Implementation is partial (some phases may be complete)
2. Plan document shows progress (checkmarks)
3. Do NOT proceed to QA
4. Report what was completed and what failed
5. Ask if they want to:
   - Continue implementation manually
   - Fix issues and retry `/implement`
   - Abort and review partial work

### QA Phase Fails

If `/qa` fails or checks fail:
1. Report QA failures
2. Implementation is complete but quality issues exist
3. Present QA report with actionable feedback
4. Ask if they want to:
   - Fix issues and re-run QA
   - Review issues manually
   - Accept current state

## Sequential Execution Notes

**CRITICAL**: Each phase MUST complete before starting the next:

1. **DO NOT** run commands in parallel
2. **WAIT** for each SlashCommand to complete
3. **CHECK** for errors after each phase
4. **EXTRACT** plan filename from planning output
5. **PASS** plan filename to implement and qa commands
6. **VALIDATE** each phase succeeded before continuing

## When to Use Oneshot vs Individual Commands

**Use `/oneshot`** when:
- Starting a new feature from scratch
- You want automated end-to-end workflow
- Feature scope is well-defined
- You trust the automation for research/planning

**Use individual commands** when:
- Researching without implementation
- Planning requires heavy customization
- Implementing existing plan
- Running QA separately
- Iterating on specific phases

## Customization Points

After generation, users can customize:
- Error handling strategies
- Verification commands between phases
- Approval gates (e.g., ask before implementation)
- Summary format
- Abort conditions

## Example Execution

```bash
# User runs:
/oneshot "Add OAuth integration for GitHub"

# What happens:
1. Research: Finds auth patterns, session handling, OAuth examples
   → Saves to .thoughts/research-2025-10-25-oauth-github.md

2. Plan: Creates 4-phase plan with success criteria
   → Saves to .thoughts/plans/2025-10-25-oauth-github.md

3. Implement: Executes all 4 phases with verification
   → Code changes, tests pass, format pass

4. QA: Validates all success criteria
   → Generates report, identifies 2 manual checks remaining

5. Summary: Shows complete workflow status
   → Feature ready for manual validation
```

## Project Type: {{PROJECT_TYPE}}

This oneshot workflow is customized for Elixir projects ({{PROJECT_TYPE}}) with:
- Test command: `{{TEST_COMMAND}}`
- Documentation: `{{DOCS_LOCATION}}`
{{#if QUALITY_TOOLS}}
- Quality tools: {{QUALITY_TOOLS_LIST}}
{{/if}}

---

**Note**: This command orchestrates other workflow commands. For more control over individual phases, use `/research`, `/plan`, `/implement`, and `/qa` separately.
