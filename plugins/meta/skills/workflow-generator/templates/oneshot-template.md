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

Mark step 5 completed, mark step 6 in_progress.

### Step 6: Final Summary

Present comprehensive workflow summary:

```markdown
✅ Oneshot Workflow Complete!

## Feature: {{FEATURE_DESCRIPTION}}

### Workflow Results

**Research Phase** ✓
- Document: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`
- Key findings: [Summarize 2-3 key patterns discovered]

**Planning Phase** ✓
- Plan: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`
- Phases: [N phases defined]
- Success criteria: [N automated, M manual checks]

**Implementation Phase** ✓
- All phases completed: [X/X]
- Verification passed: ✓ Compile, ✓ Tests, ✓ Format
{{#if QUALITY_TOOLS}}
- Quality checks: {{QUALITY_TOOLS_STATUS}}
{{/if}}

**QA Phase** ✓
- Automated checks: [PASS/FAIL summary]
- Manual validation: [Items remaining]
- Overall status: [Ready for review / Needs attention]

---

## Next Steps

{{#if QA_PASSED}}
1. Review the implementation
2. Complete manual success criteria checks
3. Create pull request
4. Deploy when ready
{{else}}
1. Address QA feedback:
   [List actionable items from QA report]
2. Re-run: `/qa PLAN_FILENAME`
3. Iterate until all checks pass
{{/if}}

---

## Generated Artifacts

- Research: `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`
- Plan: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature.md`
- QA Report: [Embedded in plan document]

**Feature is {{#if QA_PASSED}}ready for review{{else}}in progress{{/if}}!**
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
