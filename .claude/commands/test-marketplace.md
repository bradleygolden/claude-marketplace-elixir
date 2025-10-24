---
description: Test marketplace plugin(s) with intelligent failure analysis
argument-hint: [plugin-name]
allowed-tools: Bash, Write, Edit, Read, Glob, TodoWrite, Task, AskUserQuestion
---

# Marketplace Plugin Test Runner

This command runs plugin test suites with intelligent failure analysis to help debug issues quickly.

## Determine Test Scope

Plugin parameter: "$1"

- If "$1" is empty: Run ALL plugin tests
- If "$1" is provided: Run only the test for plugin "$1"

## Find Available Tests

Use the Glob tool to find all test directories:
- Pattern: `test/plugins/*/README.md`

This will show all available plugin tests (e.g., `test/plugins/core/README.md`, `test/plugins/credo/README.md`).

## Execute Tests

### Parallel Execution (when "$1" is empty)

When no specific plugin is provided, run ALL plugin tests in parallel:

1. Use TodoWrite to create test plan:
```
⏳ Running core plugin tests
⏳ Running credo plugin tests
⏳ Analyzing any failures
⏳ Generating summary report
```

2. Use Glob to find all test README files (pattern: `test/plugins/*/README.md`)

3. For EACH test README found, use the Task tool with `subagent_type="general-purpose"`

4. **CRITICAL**: Make ALL Task tool calls in a SINGLE response to enable parallel execution

5. Each agent should receive this prompt template:

```
Execute the plugin test suite defined in {test_readme_path}.

Instructions:
1. Read the test README file at {test_readme_path}
2. Follow ALL test instructions sequentially
3. Create a TodoWrite checklist to track test steps
4. Execute each test step carefully
5. Observe and record results for each test
6. Provide a final summary in the format specified in the README

Return your findings in this format:
- Plugin name: {plugin_name}
- Test results: (summary as specified in README)
- Overall result: PASS/FAIL
- Failed tests: [list any that failed with brief description]
```

6. Wait for all agents to complete

7. Collect results from each agent

8. **Analyze Failures** (if any tests failed):

a. Collect all failed plugins into a list

b. Update TodoWrite: ⏳ Analyzing failures for {comma-separated list of failed plugin names}

c. **CRITICAL**: Spawn ALL analyzer agents in parallel (single response block)

For EACH failed plugin, create a Task agent with `subagent_type="analyzer"`:

```
Use the analyzer agent to investigate test failures for {plugin-name}:

The following tests failed:
{list of failed tests with descriptions}

Please:
1. Read the plugin's implementation files:
   - plugins/{plugin-name}/.claude-plugin/plugin.json
   - plugins/{plugin-name}/hooks/hooks.json (if exists)
   - plugins/{plugin-name}/scripts/*.sh (if exist)

2. For each failed test, analyze:
   - What the test was trying to verify
   - What the plugin's implementation does
   - Why the implementation might not work as expected
   - What the execution flow reveals about the failure

3. Compare with working plugins:
   - How do other plugins handle similar functionality?
   - What patterns does this plugin use differently?

Focus on documenting what the implementation does and how it differs
from what the test expects. Don't suggest fixes, just explain the gap.

Return a detailed analysis with file:line references.
```

Make ALL Task tool calls in a SINGLE response to enable parallel execution.

d. Wait for all analyzer agents to complete

e. Update TodoWrite: ✅ Analyzed failures for all plugins

9. **Generate Comprehensive Test Report**

Update TodoWrite: ⏳ Generating summary report

Synthesize all results into a comprehensive report:

```markdown
# Marketplace Plugin Test Results

**Date**: [current date/time]
**Tests Run**: X plugins

## Overall Summary

```
[For each plugin found, list: <Plugin Name>: PASS / FAIL]

Example:
- core: PASS
- credo: FAIL

Overall: X/Y tests passed
```

---

## Detailed Results

### [Plugin 1 Name] - PASS

All tests passed successfully!

**Tests Executed**:
- ✅ Test 1: [Description]
- ✅ Test 2: [Description]
- ✅ Test 3: [Description]

---

### [Plugin 2 Name] - ❌ FAIL

**Tests Executed**:
- ✅ Test 1: [Description] - PASSED
- ❌ Test 2: [Description] - FAILED
- ⚠️ Test 3: [Description] - PARTIAL

**Failure Analysis** (analyzer):

#### Test 2: [Test Name]

**What the test expected**:
- [Expected behavior from test README]

**What happened**:
- [Actual behavior observed]

**Implementation Analysis**:

The plugin's hook at `.claude-plugin/plugins/{name}/hooks/hooks.json:X` does:
```
[Code snippet showing implementation]
```

**Execution Flow**:
1. [Step 1 of execution]
2. [Step 2 of execution]
3. [Where it fails / differs from expectation]

**Root Cause**:
[Explanation of why the implementation doesn't match test expectations]

**Comparison with Working Plugins**:

Similar functionality in [other-plugin]:
```
File: .claude-plugin/plugins/[other-plugin]/[file]:X
[Code showing working implementation]
```

Key difference: [Specific difference]

---

#### Test 3: [Test Name]

[Similar structure for each failed test]

---

## Recommendations

[IF ANY TESTS FAILED]

### For {plugin-name}:

1. **[Issue Category]**:
   - Problem: [What's not working]
   - Location: [file:line]
   - Working Example: [file:line from another plugin]
   - Consider: [What to look at, not what to do]

2. **[Issue Category]**:
   [Similar structure]

[IF ALL TESTS PASSED]

All plugins passed their test suites! The marketplace is in good health.

---

## Next Steps

[IF FAILURES EXIST]

For failed plugins:
1. Review the failure analysis above
2. Compare your implementation with working examples
3. Use `/research` to understand patterns better
4. Fix issues and rerun: `/test-marketplace {plugin-name}`

[IF ALL PASSED]

All tests passing! Consider:
- Adding more comprehensive test cases
- Testing edge cases (missing mix.exs, invalid input)
- Documenting test patterns for new plugins

---

## Test Files Referenced

[List all test README files that were executed]
```

10. **Write Detailed Report to .thoughts**

Update TodoWrite: ⏳ Writing detailed report to .thoughts

a. Create `.thoughts/` directory if it doesn't exist: `mkdir -p .thoughts`

b. Generate timestamp for filename: `date +%Y%m%d-%H%M%S`

c. Write the comprehensive test report to `.thoughts/test-marketplace-[timestamp].md` using the Write tool

d. Update TodoWrite: ✅ Detailed report written to .thoughts

11. **Present Summary to User**

Present a CONCISE summary to the user (not the full report):

```markdown
# Test Results Summary

**Tests Run**: X plugins
**Results**: X/Y tests passed

[IF ALL PASSED]
✅ All tests passed! The marketplace is healthy.

[IF SOME FAILED]
❌ Some tests failed:
- **core**: X/Y tests failed
- **credo**: X/Y tests failed

**Detailed analysis**: See `.thoughts/test-marketplace-[timestamp].md`
```

12. **Offer User Options**

Use the AskUserQuestion tool to ask the user what they'd like to do next:

[IF ANY TESTS FAILED]

```
{
  "question": "Tests have failed. How would you like to proceed?",
  "header": "Next Steps",
  "multiSelect": false,
  "options": [
    {
      "label": "Fix the issues",
      "description": "Keep test state and proceed with fixing the identified issues based on the analysis"
    },
    {
      "label": "Reset tests",
      "description": "Reset all test directories to their initial clean state for future test runs"
    },
    {
      "label": "Keep as-is",
      "description": "Leave everything in current state for manual inspection"
    }
  ]
}
```

[IF ALL TESTS PASSED]

```
{
  "question": "All tests passed! What would you like to do with the test directories?",
  "header": "Next Steps",
  "multiSelect": false,
  "options": [
    {
      "label": "Reset tests",
      "description": "Reset all test directories to clean state, ready for the next test run"
    },
    {
      "label": "Keep as-is",
      "description": "Leave test directories in their current state"
    }
  ]
}
```

13. **Handle User Choice**

Based on the user's selection:

a. **If "Fix the issues"**:
   - Update TodoWrite: ✅ All tasks completed
   - Inform user: "Test state preserved. Review the detailed analysis in `.thoughts/test-marketplace-[timestamp].md` and let me know which issues you'd like to address first."
   - DO NOT reset test files

b. **If "Reset tests"**:
   - Continue to step 14 (Reset Test Files)

c. **If "Keep as-is"**:
   - Update TodoWrite: ✅ All tasks completed
   - Inform user: "Test state preserved. Test files remain in their current state."
   - DO NOT reset test files

14. **Reset Test Files** (only if user chose "Reset tests"):

Update TodoWrite: ⏳ Resetting test files

For EACH plugin that was tested, reset the test files to their original state:

a. **Core plugin reset**:
   - No file resets needed (tests don't modify files that need resetting)

b. **Credo plugin reset**:
   - Reset `test/plugins/credo/postedit-test/lib/code_with_credo_issues.ex`:
     - Remove any test comments added during testing
     - Keep original Credo violations intact
   - Reset `test/plugins/credo/precommit-test/lib/code_with_issues.ex`:
     - Restore to original state with Credo violations
     - If file was fixed during testing, revert to broken state
   - Reset git history in test repos:
     - `cd test/plugins/credo/precommit-test && git reset --hard HEAD~N` (where N is number of test commits)

c. Update TodoWrite: ✅ Test files reset and all tasks completed

d. Confirm to user: "Test files have been reset and are ready for future test runs."

### Sequential Execution (when "$1" is provided)

When a specific plugin is provided:

1. Create test plan with TodoWrite:
```
⏳ Running {plugin-name} tests
⏳ Analyzing any failures
⏳ Generating report
```

2. Check if `test/plugins/$1/README.md` exists

3. If it doesn't exist, report an error listing available plugins:
```bash
ls test/plugins/
```

4. If it exists, execute the test directly (no agent needed):
   - Read the test README file
   - Follow ALL instructions in the README sequentially
   - Track progress using TodoWrite to create a checklist of test steps
   - Execute each test step carefully
   - Observe and record the results
   - Provide a summary as specified in the README

5. **If any tests failed**, perform failure analysis:

a. Update TodoWrite: ⏳ Analyzing failures

b. Spawn analyzer agent:

```
Use the analyzer agent to investigate test failures for {plugin-name}:

The following tests failed:
{list of failed tests}

Please analyze why these tests failed by:
1. Reading the plugin implementation in plugins/{plugin-name}/
2. Tracing the execution flow
3. Identifying where behavior differs from test expectations
4. Comparing with working plugins

Provide detailed analysis with file:line references.
```

c. Wait for analysis to complete

d. Update TodoWrite: ✅ Failure analysis completed

6. **Write Detailed Report to .thoughts**

Update TodoWrite: ⏳ Writing detailed report to .thoughts

a. Create `.thoughts/` directory if it doesn't exist: `mkdir -p .thoughts`

b. Generate timestamp for filename: `date +%Y%m%d-%H%M%S`

c. Write the comprehensive test report to `.thoughts/test-marketplace-[timestamp].md` using the Write tool

d. Update TodoWrite: ✅ Detailed report written to .thoughts

7. **Present Summary to User**

Present a CONCISE summary to the user (not the full report):

```markdown
# Test Results Summary - {plugin-name}

**Tests Run**: X tests
**Results**: X/Y tests passed

[IF ALL PASSED]
✅ All tests passed for {plugin-name}!

[IF SOME FAILED]
❌ Some tests failed:
- [List of failed tests]

**Detailed analysis**: See `.thoughts/test-marketplace-[timestamp].md`
```

8. **Offer User Options**

Use the AskUserQuestion tool to ask the user what they'd like to do next:

[IF ANY TESTS FAILED]

```
{
  "question": "Tests have failed. How would you like to proceed?",
  "header": "Next Steps",
  "multiSelect": false,
  "options": [
    {
      "label": "Fix the issues",
      "description": "Keep test state and proceed with fixing the identified issues based on the analysis"
    },
    {
      "label": "Reset tests",
      "description": "Reset test directory to initial clean state for future test runs"
    },
    {
      "label": "Keep as-is",
      "description": "Leave everything in current state for manual inspection"
    }
  ]
}
```

[IF ALL TESTS PASSED]

```
{
  "question": "All tests passed! What would you like to do with the test directory?",
  "header": "Next Steps",
  "multiSelect": false,
  "options": [
    {
      "label": "Reset tests",
      "description": "Reset test directory to clean state, ready for the next test run"
    },
    {
      "label": "Keep as-is",
      "description": "Leave test directory in its current state"
    }
  ]
}
```

9. **Handle User Choice**

Based on the user's selection:

a. **If "Fix the issues"**:
   - Update TodoWrite: ✅ All tasks completed
   - Inform user: "Test state preserved. Review the detailed analysis in `.thoughts/test-marketplace-[timestamp].md` and let me know which issues you'd like to address first."
   - DO NOT reset test files

b. **If "Reset tests"**:
   - Continue to step 10 (Reset Test Files)

c. **If "Keep as-is"**:
   - Update TodoWrite: ✅ All tasks completed
   - Inform user: "Test state preserved. Test files remain in their current state."
   - DO NOT reset test files

10. **Reset Test Files** (only if user chose "Reset tests"):

Update TodoWrite: ⏳ Resetting test files for {plugin-name}

Reset the test files for the specific plugin tested:

a. **If testing core plugin**:
   - No file resets needed (tests don't modify files that need resetting)

b. **If testing credo plugin**:
   - Reset `test/plugins/credo/postedit-test/lib/code_with_credo_issues.ex`:
     - Remove any test comments added during testing
     - Keep original Credo violations intact
   - Reset `test/plugins/credo/precommit-test/lib/code_with_issues.ex`:
     - Restore to original state with Credo violations
     - If file was fixed during testing, revert to broken state
   - Reset git history in test repos:
     - `cd test/plugins/credo/precommit-test && git reset --hard HEAD~N` (where N is number of test commits)

c. Update TodoWrite: ✅ Test files reset and all tasks completed

d. Confirm to user: "Test files have been reset and are ready for future test runs."

## Important Notes

- **Detailed Reports**: Full test reports are saved to `.thoughts/test-marketplace-[timestamp].md` for reference
- **Concise Summaries**: User sees a brief summary, with option to dive into detailed analysis in .thoughts
- **Interactive Workflow**: User chooses whether to fix issues, reset tests, or keep current state
- **Parallel Execution**: When testing all plugins, agents run concurrently for faster results
- **Agent Independence**: Each agent has its own context window and executes tests independently
- **Single Plugin Mode**: When a specific plugin is provided, tests run directly (no agent spawned)
- **Intelligent Failure Analysis**: When tests fail, analyzer agents investigate root causes. Multiple analyzers spawn in parallel when multiple plugins fail
- **Comparison with Working Examples**: Failure analysis shows how successful plugins implement similar features
- **Non-judgmental**: Analysis explains what's different, not what's "wrong"
- **Actionable Insights**: Every analysis includes file:line references to working examples
- **Optional Reset**: Tests are NOT automatically reset - user decides whether to reset, fix, or keep current state

## Failure Analysis Philosophy

When tests fail, the analysis:
- ✅ Explains what the implementation does vs. what the test expects
- ✅ Traces execution flow to identify where behavior diverges
- ✅ Shows how working plugins handle similar functionality
- ✅ Provides file:line references for comparison
- ❌ Does NOT suggest specific fixes (helps you understand, you decide)
- ❌ Does NOT judge if the implementation is good or bad
- ❌ Does NOT criticize design decisions

The goal is to help you understand WHY tests fail so you can make informed decisions about fixes.

## Example Failure Analysis Output

```markdown
### Test: Auto-format Hook - ❌ FAIL

**Expected**: File should be automatically formatted after Write tool

**Observed**: File remained unformatted

**Implementation Analysis**:

Hook at `.claude-plugin/plugins/my-plugin/hooks/hooks.json:9`:
```json
{
  "command": "FILE_PATH=$(jq -r '.tool_input.file_path'); mix format \"$FILE_PATH\""
}
```

**Execution Flow**:
1. Hook triggers on Edit/Write
2. Attempts to extract FILE_PATH using jq in subshell
3. Subshell doesn't receive stdin (no pipe from parent)
4. FILE_PATH is empty
5. mix format runs with empty path
6. No formatting occurs

**Root Cause**:
The command substitution `$(jq...)` creates a subshell that doesn't
automatically receive stdin. The hook JSON is passed via stdin by
Claude Code, but the subshell can't access it.

**Working Example**:

Core plugin at `.claude-plugin/plugins/core/hooks/hooks.json:9`:
```json
{
  "command": "jq -r '.tool_input.file_path' | while read FILE_PATH; do mix format \"$FILE_PATH\"; done"
}
```

**Key Difference**:
Core plugin uses pipeline pattern that pipes jq output directly to
while loop, which can read from stdin properly.
```

## Test Report Sections

Every test report includes:

1. **Overall Summary**: Quick stats on pass/fail
2. **Detailed Results**: Per-plugin breakdown
3. **Failure Analysis** (if applicable): Deep dive into why tests failed
4. **Comparisons**: Working examples from other plugins
5. **Recommendations**: Areas to investigate (not prescriptive fixes)
6. **Next Steps**: What to do with the findings

## Benefits of Intelligent Testing

- **Fast Debugging**: Understand failures immediately
- **Learn from Examples**: See how working plugins differ
- **Root Cause Analysis**: Not just "it failed" but "here's why"
- **Self-Service**: Detailed enough to fix issues without asking for help
- **Pattern Discovery**: Learn marketplace patterns through testing

## Output Format

Test results are saved to `.thoughts/test-marketplace-[timestamp].md` with:
- **Timestamp**: Format `YYYYMMDD-HHMMSS` (e.g., `20251023-143022`)
- **Full Report**: Complete test results, failure analysis, and recommendations
- **Persistent**: Files remain in .thoughts for historical reference
- **User Summary**: Concise overview shown to user with path to detailed report

Example output flow:
1. Tests execute and generate comprehensive analysis
2. Full report written to `.thoughts/test-marketplace-20251023-143022.md`
3. User sees brief summary: "❌ 2/5 tests failed. Detailed analysis: See `.thoughts/test-marketplace-20251023-143022.md`"
4. User chooses next action (fix, reset, or keep as-is)
