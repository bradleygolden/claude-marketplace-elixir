---
description: Comprehensive quality assurance and validation for Elixir projects
argument-hint: [optional-plan-name]
allowed-tools: Read, Grep, Glob, Task, Bash, TodoWrite, Write
---

# QA

Systematically validate Elixir implementation against quality standards and success criteria.

**Project Type**: {{PROJECT_TYPE}}

## Purpose

Validate completed work through automated checks, code review, and comprehensive quality analysis to ensure implementation meets standards.

## Steps to Execute:

### Step 1: Determine Scope

**If plan name provided:**
- Locate plan file: `{{DOCS_LOCATION}}/plans/*[plan-name]*.md`
- Read plan completely
- Extract success criteria
- Validate implementation against that plan

**If no plan provided:**
- General Elixir project health check
- Run all quality tools
- Review recent changes
- Provide overall quality assessment

### Step 2: Initial Discovery

**Read implementation plan** (if validating against plan):
```bash
find {{DOCS_LOCATION}}/plans -name "*[plan-name]*.md" -type f
```

**Gather git evidence:**
```bash
# See what changed
git status
git diff --stat
git log --oneline -10

# If validating a specific branch
git diff main...HEAD --stat
```

**Create validation plan** using TodoWrite:
```
1. [in_progress] Gather context and plan
2. [pending] Run automated quality checks
3. [pending] Spawn validation agents
4. [pending] Check manual criteria
5. [pending] Generate validation report
6. [pending] Offer fix plan generation if critical issues found
```

### Step 3: Run Automated Quality Checks

Run all automated checks in parallel using separate Bash commands:

**Compilation Check:**
```bash
mix clean && mix compile --warnings-as-errors
```

**Test Suite:**
```bash
{{TEST_COMMAND}}
```

**Format Validation:**
```bash
mix format --check-formatted
```

{{QUALITY_TOOL_COMMANDS}}

**Capture results** from each check:
- Exit code (0 = pass, non-zero = fail)
- Output messages
- Any warnings or errors

Mark this step complete in TodoWrite.

### Step 4: Spawn Validation Agents

Use Task tool to spawn parallel validation agents:

**Agent 1: Code Review** (subagent_type="general-purpose"):
```
Review the Elixir code changes for:
- Module organization and naming conventions
- Function documentation (@moduledoc, @doc)
- Pattern matching best practices
- Error handling (tuple returns, with blocks)
- Code clarity and readability
- Adherence to Elixir idioms

Focus on:
- Context boundaries (if Phoenix)
- Ecto query patterns
- GenServer/Agent usage
- Supervisor tree organization

Provide file:line references for all observations.
Document current implementation (not suggestions for improvement).
```

**Agent 2: Test Coverage** (subagent_type="general-purpose"):
```
Analyze test coverage for the implementation:
- Find all test files related to changes
- Check if all public functions have tests
- Verify both success and error cases are tested
- Check for edge case coverage
- Identify any untested code paths

ExUnit-specific:
- describe blocks usage
- test naming conventions
- setup/teardown patterns
- assertion quality

Provide file:line references.
Document what is tested, not what should be tested.
```

**Agent 3: Documentation Review** (subagent_type="general-purpose"):
```
Review documentation completeness:
- @moduledoc present and descriptive
- @doc on all public functions
- @typedoc on public types
- Inline documentation for complex logic
- README updates if needed

Check for:
- Code examples in docs
- Clear explanations
- Accurate descriptions

Provide file:line references.
Document current documentation state.
```

**Wait for all agents** to complete before proceeding.

Mark this step complete in TodoWrite.

### Step 5: Verify Success Criteria

**If validating against plan:**

**Read success criteria** from plan:
- Automated verification section
- Manual verification section

**Check automated criteria:**
- Match each criterion against actual checks
- Confirm all automated checks passed
- Note any that failed

**Check manual criteria:**
- Review each manual criterion
- Assess whether it's met (check implementation)
- Document status for each

**If general health check:**

**Automated Health Indicators:**
- Compilation succeeds
- All tests pass
- Format check passes
- Quality tools pass (if configured)

**Manual Health Indicators:**
- Recent changes are logical
- Code follows project patterns
- No obvious bugs or issues
- Documentation is adequate

Mark this step complete in TodoWrite.

### Step 6: Elixir-Specific Quality Checks

**Module Organization:**
- Are modules properly namespaced?
- Is module structure clear (use, import, alias at top)?
- Are public vs private functions clearly separated?

**Pattern Matching:**
- Are function heads used effectively?
- Is pattern matching preferred over conditionals?
- Are guard clauses used appropriately?

**Error Handling:**
- Are tuple returns used ({:ok, result}/{:error, reason})?
- Are with blocks used for complex error flows?
- Are errors propagated correctly?

**Phoenix-Specific** (if {{PROJECT_TYPE}} is Phoenix):
- Are contexts properly bounded?
- Do controllers delegate to contexts?
- Are LiveViews structured correctly (mount, handle_event, render)?
- Are routes organized logically?

**Ecto-Specific:**
- Are schemas properly defined?
- Are changesets comprehensive (validations, constraints)?
- Are queries composable and efficient?
- Are transactions used where needed?

**Process-Based** (GenServer, Agent, Task):
- Is supervision tree correct?
- Are processes named appropriately?
- Is message passing clear?
- Are process lifecycles managed?

Mark this step complete in TodoWrite.

### Step 7: Generate Validation Report

**Compile all findings:**
- Automated check results
- Agent findings (code review, tests, docs)
- Success criteria status
- Elixir-specific observations

**Create validation report structure:**

```markdown
---
date: [ISO timestamp]
validator: [Git user name]
commit: [Current commit hash]
branch: [Current branch name]
plan: [Plan name if applicable]
status: [PASS / PASS_WITH_WARNINGS / FAIL]
tags: [qa, validation, elixir, {{PROJECT_TYPE_TAGS}}]
---

# QA Report: [Plan Name or "General Health Check"]

**Date**: [Current date and time]
**Validator**: [Git user name]
**Commit**: [Current commit hash]
**Branch**: [Current branch]
**Project Type**: {{PROJECT_TYPE}}

## Executive Summary

**Overall Status**: ✅ PASS / ⚠️ PASS WITH WARNINGS / ❌ FAIL

**Quick Stats:**
- Compilation: ✅/❌
- Tests: [N] passed, [N] failed
{{QUALITY_TOOLS_RESULTS_SUMMARY}}
- Code Review: [N] observations
- Test Coverage: [Assessment]
- Documentation: [Assessment]

## Automated Verification Results

### Compilation
```
[Output from mix compile]
```
**Status**: ✅ Success / ❌ Failed
**Issues**: [List any warnings or errors]

### Test Suite
```
[Output from test command]
```
**Status**: ✅ All passed / ❌ [N] failed
**Failed Tests**:
- [test name] - [reason]

### Code Formatting
```
[Output from mix format --check-formatted]
```
**Status**: ✅ Formatted / ❌ Needs formatting

{{QUALITY_TOOLS_DETAILED_RESULTS}}

## Agent Validation Results

### Code Review Findings

[Findings from code review agent]

**Observations** ([N] total):
1. [file:line] - [Observation about current implementation]
2. [file:line] - [Observation]

### Test Coverage Analysis

[Findings from test coverage agent]

**Coverage Assessment**:
- Public functions tested: [N]/[M]
- Edge cases covered: [Assessment]
- Untested paths: [List if any]

### Documentation Review

[Findings from documentation agent]

**Documentation Status**:
- Modules documented: [N]/[M]
- Public functions documented: [N]/[M]
- Quality assessment: [Good/Adequate/Needs Work]

## Success Criteria Validation

[If validating against plan, list each criterion]

**Automated Criteria**:
- [x] Compilation succeeds
- [x] {{TEST_COMMAND}} passes
{{SUCCESS_CRITERIA_CHECKLIST}}

**Manual Criteria**:
- [x] Feature works as expected
- [ ] Edge cases handled [Status]
- [x] Documentation updated

## Elixir-Specific Observations

**Module Organization**: [Assessment]
**Pattern Matching**: [Assessment]
**Error Handling**: [Assessment]
{{PROJECT_TYPE_SPECIFIC_OBSERVATIONS}}

## Issues Found

[If any issues, list them by severity]

### Critical Issues (Must Fix)
[None or list]

### Warnings (Should Fix)
[None or list]

### Recommendations (Consider)
[None or list]

## Overall Assessment

[IF PASS]
✅ **IMPLEMENTATION VALIDATED**

All quality checks passed:
- Automated verification: Complete
- Code review: No issues
- Tests: All passing
- Documentation: Adequate

Implementation meets quality standards and is ready for merge/deploy.

[IF PASS WITH WARNINGS]
⚠️ **PASS WITH WARNINGS**

Core functionality validated but some areas need attention:
- [List warning areas]

Address warnings before merge or create follow-up tasks.

[IF FAIL]
❌ **VALIDATION FAILED**

Critical issues prevent approval:
- [List critical issues]

Fix these issues and re-run QA: `/qa "[plan-name]"`

## Next Steps

[IF PASS]
- Merge to main branch
- Deploy (if applicable)
- Close related tickets

[IF PASS WITH WARNINGS]
- Address warnings
- Re-run QA or accept warnings and proceed
- Document accepted warnings

[IF FAIL]
- Fix critical issues
- Address failing tests
- Re-run: `/qa "[plan-name]"`
```

Save report to: `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-[plan-name]-qa.md`

Mark this step complete in TodoWrite.

### Step 8: Present Results

**Show concise summary to user:**

```markdown
# QA Validation Complete

**Plan**: [Plan name or "General Health Check"]
**Status**: ✅ PASS / ⚠️ PASS WITH WARNINGS / ❌ FAIL

## Results Summary

**Automated Checks**:
- Compilation: ✅
- Tests: ✅ [N] passed
{{QUALITY_TOOLS_SUMMARY_DISPLAY}}

**Code Quality**:
- Code Review: [N] observations
- Test Coverage: [Good/Adequate/Needs Work]
- Documentation: [Good/Adequate/Needs Work]

**Detailed Report**: `{{DOCS_LOCATION}}/qa-reports/YYYY-MM-DD-[plan-name]-qa.md`

[IF FAIL]
**Critical Issues**:
1. [Issue with file:line]
2. [Issue with file:line]

Fix these and re-run: `/qa "[plan-name]"`

[IF PASS]
**Ready to merge!** ✅
```

### Step 9: Offer Fix Plan Generation (Conditional)

**Only execute this step if overall status is ❌ FAIL**

If QA detected critical issues:

**9.1 Count Critical Issues**

Count issues from validation report that are marked as ❌ CRITICAL or blocking.

**9.2 Prompt User for Fix Plan Generation**

Use AskUserQuestion tool:
```
Question: "QA detected [N] critical issues. Generate a fix plan to address them?"
Header: "Fix Plan"
Options (multiSelect: false):
  Option 1:
    Label: "Yes, generate fix plan"
    Description: "Create a detailed plan to address all critical issues using /plan command"
  Option 2:
    Label: "No, I'll fix manually"
    Description: "Exit QA and fix issues manually, then re-run /qa"
```

**9.3 If User Selects "Yes, generate fix plan":**

**9.3.1 Extract QA Report Filename**

Get the most recent QA report generated in Step 7:
```bash
ls -t {{DOCS_LOCATION}}/qa-reports/*-qa.md 2>/dev/null | head -1
```

Store filename in variable: QA_REPORT_PATH

**9.3.2 Invoke Plan Command**

Use SlashCommand tool:
```
Command: /plan "Fix critical issues from QA report: [QA_REPORT_PATH]"
```

Wait for plan generation to complete.

**9.3.3 Extract Plan Filename**

Parse the output from /plan command to find the generated plan filename.
Typical format: `{{DOCS_LOCATION}}/plans/plan-YYYY-MM-DD-fix-*.md`

Store plan name without path/extension in variable: FIX_PLAN_NAME

Report to user:
```
Fix plan created at: [PLAN_FILENAME]
```

**9.3.4 Prompt User for Plan Execution**

Use AskUserQuestion tool:
```
Question: "Fix plan created. Execute the fix plan now?"
Header: "Execute Plan"
Options (multiSelect: false):
  Option 1:
    Label: "Yes, execute fix plan"
    Description: "Run /implement to apply fixes, then re-run /qa for validation"
  Option 2:
    Label: "No, I'll review first"
    Description: "Exit and review the plan manually before implementing"
```

**9.3.5 If User Selects "Yes, execute fix plan":**

Use SlashCommand tool:
```
Command: /implement "[FIX_PLAN_NAME]"
```

Wait for implementation to complete.

Report:
```
Fix implementation complete. Re-running QA for validation...
```

Use SlashCommand tool:
```
Command: /qa
```

Wait for QA to complete.

Report:
```
Fix cycle complete. Check QA results above.
```

**9.3.6 If User Selects "No, I'll review first":**

Report:
```
Fix plan saved at: [PLAN_FILENAME]

When ready to implement:
  /implement "[FIX_PLAN_NAME]"

After implementing, re-run QA:
  /qa
```

**9.4 If User Selects "No, I'll fix manually":**

Report:
```
Manual fixes required.

Critical issues documented in: [QA_REPORT_PATH]

After fixing, re-run QA:
  /qa
```

**9.5 If QA Status is NOT ❌ FAIL:**

Skip this step entirely (no fix plan offer needed).

## Quality Tool Integration

{{QUALITY_TOOL_INTEGRATION_GUIDE}}

## Important Guidelines

### Automated vs Manual

**Automated Verification:**
- Must be runnable via command
- Exit code determines pass/fail
- Repeatable and consistent

**Manual Verification:**
- Requires human judgment
- UI/UX quality
- Business logic correctness
- Edge case appropriateness

### Thoroughness

**Be comprehensive:**
- Run all configured quality tools
- Spawn all validation agents
- Check all success criteria
- Document all findings

**Be objective:**
- Report what you find
- Don't minimize issues
- Don't over-report non-issues
- Focus on facts

### Validation Philosophy

**Not a rubber stamp:**
- Real validation, not formality
- Find real issues
- Assess true quality

**Not overly strict:**
- Focus on significant issues
- Warnings vs failures
- Practical quality bar

## Edge Cases

### If Plan Doesn't Exist

User provides plan name but file not found:
- Search {{DOCS_LOCATION}}/plans/
- List available plans
- Ask user to clarify or choose

### If No Changes Detected

Running QA but no git changes:
- Note in report
- Run general health check anyway
- Report clean state

### If Tests Have Pre-Existing Failures

Tests failing before this implementation:
- Document which tests are pre-existing
- Focus on new failures
- Note technical debt in report

### If Quality Tools Not Installed

If Credo, Dialyzer, etc. not in mix.exs:
- Note in report
- Skip that tool
- Don't fail validation for missing optional tools

## Example Session

**User**: `/qa "user-authentication"`

**Process**:
1. Find plan: `{{DOCS_LOCATION}}/plans/2025-01-23-user-authentication.md`
2. Read success criteria from plan
3. Run automated checks (compile, test, format, Credo, Dialyzer)
4. Spawn 3 validation agents (code review, test coverage, docs)
5. Wait for agents to complete
6. Verify success criteria
7. Check Elixir-specific patterns
8. Generate comprehensive report
9. Present summary: "✅ PASS - All 12 success criteria met"
