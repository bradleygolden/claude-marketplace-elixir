---
description: Comprehensive QA validation for marketplace (review, validate, test)
argument-hint: "[action] [target] - action: review|validate|test (default: all), target: plugin name for validate/test"
allowed-tools: Bash, Read, Glob, Write, Edit, TodoWrite, Task, Grep
---

# QA Command - Unified Quality Assurance

This command provides comprehensive quality assurance for the Claude Code plugin marketplace.

## Usage

```bash
# Run everything (review + validate all + test all)
/qa

# Run specific action
/qa review                    # Pre-push code review only
/qa test [plugin-name]        # Test all or specific plugin
/qa validate <plugin-name>    # Validate specific plugin

# Combined examples
/qa test core                 # Test only core plugin
/qa validate ash              # Validate only ash plugin
```

## Overview

By default, `/qa` runs ALL quality checks:
1. **Review**: Pre-push code review of all changes
2. **Test**: Run full test suite for all plugins
3. **Validate**: Validate all plugins in marketplace

Or run specific actions when you provide an argument.

---

## Execution Flow

**Default Mode (`/qa` with no arguments)** runs 5 phases sequentially:

```
Phase 0: Settings Configuration
    ↓ (sequential)
Phase 1: Marketplace Review
    ├─ Spawn 5 agents in PARALLEL (single message):
    │  ├─ Plugin/Hook Analysis (analyzer)
    │  ├─ Command/Agent Review (finder)
    │  ├─ Comment Cleanup (comment-cleaner)
    │  ├─ Version Management (analyzer)
    │  └─ Documentation Consistency (finder)
    ↓ (wait for all agents, then sequential)
Phase 2: Run All Plugin Tests
    ↓ (sequential)
Phase 3: Validate All Plugins
    ↓ (sequential)
Phase 4: Generate Consolidated QA Report
```

**Specific Actions** execute only their respective phase:
- `/qa review` → Phase 1 only
- `/qa test [plugin]` → Phase 2 only
- `/qa validate <plugin>` → Phase 3 only (single plugin)

**Key Points**:
- Agents within Phase 1 run in PARALLEL (spawned in single message)
- Phases themselves run SEQUENTIALLY (wait for previous phase to complete)
- Each phase updates TodoWrite progress in real-time

---

## Step 1: Parse Arguments and Create Plan

Parse command arguments:
- `$1` = action (review, test, validate, or empty for "all")
- `$2` = target (plugin-name for validate/test, optional)

Determine execution plan based on arguments:

**If `$1` is empty**: Run ALL actions
- Use TodoWrite with these tasks:
  1. Validate settings.json plugin configuration
  2. Run marketplace review
  3. Run all plugin tests
  4. Validate all plugins
  5. Generate consolidated QA report

**If `$1` is "review"**: Run review only
- Use TodoWrite with these tasks:
  1. Identify changed files
  2. Run parallel analysis agents
  3. Run best practices validators
  4. Synthesize review report
  5. Write review document
  6. Generate changelog (if applicable)
  7. Present concise summary

**If `$1` is "test"**: Run tests only
- Use TodoWrite with these tasks:
  1. Determine test scope (all or specific plugin from `$2`)
  2. Run test scripts
  3. Parse test output
  4. Generate test report
  5. Present results

**If `$1` is "validate"**: Run validation only
- If `$2` is empty, error: "Usage: /qa validate <plugin-name>"
- Use TodoWrite with these tasks:
  1. Validate plugin exists
  2. Fast structural validation
  3. Best practices analysis (finder)
  4. Hook implementation analysis (analyzer)
  5. Test quality review (finder)
  6. Generate validation report
  7. Present report

Mark appropriate first todo as in_progress and proceed.

---

## Step 2A: Execute "All" Actions (Default)

**Only execute this step if `$1` is empty (default behavior).**

Run all quality checks in sequence, tracking progress with TodoWrite.

### Phase 0: Validate Settings Configuration

Mark first todo as in_progress: "⏳ Validate settings.json plugin configuration → in progress"

This phase ensures all marketplace plugins are properly configured in `.claude/settings.json`.

#### 0.1 Read Marketplace Plugins

Read and parse marketplace.json to get all available plugins:
```bash
jq -r '.plugins[].name' .claude-plugin/marketplace.json
```

Store the list of plugin names (e.g., core, credo, ash, dialyzer).

#### 0.2 Read Settings Configuration

Read and parse settings.json to get enabled plugins:
```bash
jq -r '.enabledPlugins | keys[]' .claude/settings.json 2>/dev/null || echo "{}"
```

Extract plugin names (e.g., core@elixir, credo@elixir).

#### 0.3 Compare and Identify Missing Plugins

For each plugin in marketplace.json:
- Check if `<plugin-name>@elixir` exists in settings.json enabledPlugins
- If missing, add to missing plugins list

#### 0.4 Report and Fix

**If missing plugins found**:

Generate list of missing plugins with proper format (e.g., `ash@elixir`, `dialyzer@elixir`).

Update settings.json to add missing plugins:
```bash
# For each missing plugin, add it to enabledPlugins
jq '.enabledPlugins["<plugin-name>@elixir"] = true' .claude/settings.json
```

Use Edit tool to update `.claude/settings.json` to add all missing plugins at once.

**Report**:
```markdown
⚠️ Settings Configuration Updated

Added missing plugins to .claude/settings.json:
- <plugin-name>@elixir
- <plugin-name>@elixir

All marketplace plugins are now enabled in settings.
```

**If no missing plugins**:
```markdown
✅ Settings Configuration Valid

All marketplace plugins are properly configured in .claude/settings.json.
```

Mark first todo as completed: "✅ Validate settings.json plugin configuration → completed"

### Phase 1: Run Marketplace Review

Mark second todo as in_progress: "⏳ Run marketplace review → in progress"

Execute the complete review process (from review-marketplace.md):

#### 1.1 Identify Changed Files

Use Bash:
```bash
git status --short && git diff --cached --name-only && git diff --name-only
```

Categorize changes by type:
- Plugin files (plugin.json, hooks.json, scripts)
- Slash commands (.claude/commands/*.md)
- Sub-agent definitions (.claude/agents/*.md)
- Tests (test/plugins/**)
- Documentation (README.md, *.md)
- Marketplace metadata (marketplace.json)

#### 1.2 Spawn Parallel Analysis Agents

Spawn FIVE parallel sub-agent tasks using Task tool in a single response:

**Task 1: Plugin/Hook Changes Analysis**
- Use Task tool with `subagent_type="analyzer"`
- Trace execution flow for changed plugin.json, hooks.json, or script files
- Verify hook matchers, patterns, blocking behavior, error handling
- Compare with working marketplace patterns

**Task 2: Command/Agent Review**
- Use Task tool with `subagent_type="finder"`
- Verify sub-agent usage in .claude/commands/*.md and .claude/agents/*.md
- Check if command follows marketplace patterns
- Validate output structure and TodoWrite usage

**Task 3: Comment Cleanup**
- Use Task tool with `subagent_type="comment-cleaner"`
- Find all files with comments in changeset
- Evaluate every comment (remove unnecessary, keep critical)
- Automatically clean up files
- Provide detailed report

**Task 4: Version Management Validation**
- Use Task tool with `subagent_type="analyzer"`
- Compare current branch with main to determine changes
- Validate version bumps according to versioning protocol:
  - **Plugin versions**: Bump when plugin functionality changes (hooks, scripts, commands, agents)
  - **Marketplace version**: Bump ONLY when catalog structure changes (add/remove plugins, marketplace metadata)
  - This follows standard package registry practices (npm, PyPI) where registry version ≠ package versions
- Check version format (semver)
- Compare with main: `git diff main -- .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json`
- Verify: If only plugin functionality changed, marketplace version should be unchanged

**Task 5: Documentation Consistency Validation**
- Use Task tool with `subagent_type="finder"`
- Check ALL documentation files for outdated patterns (regardless of whether they changed):
  - `CLAUDE.md`: Hook blocking patterns, exit codes, version management guidance
  - All `plugins/*/README.md`: Hook implementation details, exit codes, stderr/stdout usage
  - Main `README.md`: Setup instructions, hook behavior descriptions
- Search for known outdated patterns:
  - "exit 2" for blocking (should be "exit 0 with JSON permissionDecision")
  - "stderr" for blocking output (should be "stdout with JSON")
  - "Keep versions in sync" (should explain independent plugin/marketplace versioning)
  - Any references to old blocking mechanisms
- For each outdated pattern found, provide:
  - File path and line number
  - Current (outdated) text
  - What it should say (corrected text based on current implementation)
  - Severity: ⚠️ WARNING (outdated documentation)
- Report count of outdated patterns by file

Wait for ALL five agents to complete.

#### 1.3 Best Practices Validation

After Phase 2 agents complete, identify changed file types and spawn validators in parallel.

For each file type with changes, use Task tool with `subagent_type="finder"`:

**Command Validator** (if .claude/commands/*.md changed):
- Validate against Claude Code slash command best practices
- Check: frontmatter, TodoWrite usage, tool usage, execution patterns
- Report: ❌ CRITICAL / ⚠️ WARNING / 💡 RECOMMENDATION

**Agent Validator** (if .claude/agents/*.md changed):
- Validate against Claude Code agent best practices
- Check: frontmatter, tool restrictions, model selection, scope
- Report violations with severity

**Hook Validator** (if plugins/*/hooks/*.json changed):
- Validate against Claude Code plugin hooks best practices
- Check: JSON structure, matchers, blocking behavior, timeouts
- Report violations with severity

**Script Validator** (if plugins/*/scripts/*.sh changed):
- Validate against Claude Code hook script best practices
- Check: exit codes, stderr/stdout usage, error handling, shebang
- Report violations with severity

**Documentation Validator** (if README files changed):
- Validate against marketplace documentation standards
- Check: required sections, examples, formatting
- Report violations with severity

Wait for all validators to complete.

#### 1.4 Synthesize Review Report

Generate comprehensive review with:
1. Executive Summary (counts, overall assessment)
2. Changed Files by Category
3. Plugin/Hook Changes details
4. Command/Agent Changes details
5. Comment Cleanup Results
6. Version Management Validation
7. Documentation Consistency Validation (outdated patterns found)
8. Best Practices Validation results
9. Test Coverage assessment
10. Documentation assessment
11. Actionable Next Steps

#### 1.5 Write Review Document

Generate review metadata:
```bash
git config user.name && git rev-parse HEAD && git branch --show-current && git remote get-url origin | sed 's/.*[:/]\([^/]*\/[^/]*\)\.git/\1/' && date -u +"%Y-%m-%dT%H:%M:%SZ" && date +"%Y-%m-%d"
```

Create review document:
- Filename: `.thoughts/YYYY-MM-DD-marketplace-review.md`
- Include YAML frontmatter with metadata
- Include full review content from synthesis
- Use Write tool

#### 1.6 Generate Changelog (if appropriate)

Only if status is ✅ READY TO PUSH or ⚠️ NEEDS WORK (skip if ❌ DO NOT PUSH):

Spawn changelog-curator subagent:
- Use Task tool with `subagent_type="changelog-curator"`
- Analyze current branch vs main
- Generate Keep a Changelog format entries
- Recommend semantic version bump
- Save to `.thoughts/CHANGELOG-draft-YYYY-MM-DD.md`

Mark second todo as completed: "✅ Run marketplace review → completed"

### Phase 2: Run All Plugin Tests

Mark third todo as in_progress: "⏳ Run all plugin tests → in progress"

#### 2.1 Execute All Tests

Run all tests using Bash:
```bash
./test/run-all-tests.sh
```

Capture output and exit code.

#### 2.2 Parse Test Output

Extract:
- Total tests run
- Tests passed
- Tests failed
- Which specific tests failed (if any)

#### 2.3 Generate Test Report

Create `.thoughts/` directory if needed:
```bash
mkdir -p .thoughts && date +%Y%m%d-%H%M%S
```

Generate report with:
- Overall summary (total/passed/failed)
- Detailed results
- Failed tests section
- Next steps
- Test coverage details

Write to `.thoughts/test-marketplace-[timestamp].md`

Mark third todo as completed: "✅ Run all plugin tests → completed"

### Phase 3: Validate All Plugins

Mark fourth todo as in_progress: "⏳ Validate all plugins → in progress"

#### 3.1 Get All Plugin Names

List all plugins:
```bash
ls plugins/
```

#### 3.2 Validate Each Plugin

For each plugin found, run validation:

**Structural Validation**:
- Directory structure
- JSON syntax (plugin.json, marketplace.json, hooks.json)
- plugin.json field validation
- marketplace.json registration
- Script validation (if present)

Report: ❌ FAIL / ⚠️ WARN / ✅ PASS for each check

**Intelligent Analysis** (only if structural passes):

Spawn three parallel sub-agents per plugin:

1. **Best Practices Pattern Analysis** (finder):
   - Find marketplace patterns
   - Compare plugin implementation
   - Provide file:line examples

2. **Hook Implementation Analysis** (analyzer, if hooks exist):
   - Trace execution flow for each hook
   - Document stdin handling, project detection, file filtering, exit codes
   - Identify observations

3. **Test Quality Comparison** (finder):
   - Compare test suite against marketplace patterns
   - Identify missing test scenarios

Wait for all agents to complete.

**Generate Validation Report** for each plugin:
- Validation summary
- Structural validation results
- Best practices analysis
- Hook implementation analysis
- Test quality review
- Overall assessment
- Next steps

Collect all plugin validation results.

Mark fourth todo as completed: "✅ Validate all plugins → completed"

### Phase 4: Generate Consolidated QA Report

Mark fifth todo as in_progress: "⏳ Generate consolidated QA report → in progress"

#### 4.1 Aggregate All Results

Collect:
- Review report results (from .thoughts/YYYY-MM-DD-marketplace-review.md)
- Test results (from .thoughts/test-marketplace-[timestamp].md)
- All plugin validation results

#### 4.2 Create Consolidated Report

Generate comprehensive QA report:

```markdown
# Consolidated QA Report

**Date**: [current date/time]
**Branch**: [current branch]
**Commit**: [current commit hash]

## Executive Summary

**Overall Status**: ✅ ALL PASS / ⚠️ NEEDS ATTENTION / ❌ CRITICAL ISSUES

Quick Stats:
- Settings: [status] - [plugin count] plugins configured
- Review: [status] - [critical count] ❌ / [warning count] ⚠️ / [recommendation count] 💡
- Tests: [status] - [passed]/[total] tests passed
- Validation: [status] - [plugin count] plugins validated

---

## 0. Settings Configuration

**Status**: ✅ ALL CONFIGURED / ⚠️ PLUGINS ADDED

**Summary**:
- Marketplace plugins: X
- Configured plugins: X
- Missing plugins: X (added automatically)

**Plugins Added** (if any):
- <plugin-name>@elixir
- <plugin-name>@elixir

**Result**: All marketplace plugins are now enabled in `.claude/settings.json`

---

## 1. Marketplace Review

**Status**: ✅ READY TO PUSH / ⚠️ NEEDS WORK / ❌ DO NOT PUSH

**Summary**:
- Files changed: X
- Critical issues: X ❌
- Warnings: X ⚠️
- Recommendations: X 💡
- Documentation consistency: X outdated patterns found
- Best practices violations: X ❌ / X ⚠️ / X 💡

**Documentation Issues** (if any):
- `CLAUDE.md`: X outdated patterns
- `plugins/*/README.md`: X outdated patterns
- Main `README.md`: X outdated patterns

**Details**: See `.thoughts/YYYY-MM-DD-marketplace-review.md`

**Changelog**: `.thoughts/CHANGELOG-draft-YYYY-MM-DD.md` (if generated)

---

## 2. Test Results

**Status**: ✅ ALL PASSED / ❌ FAILURES DETECTED

**Summary**:
- Total tests: X
- Passed: X
- Failed: X

**Failed Tests** (if any):
- [List failed test names]

**Details**: See `.thoughts/test-marketplace-[timestamp].md`

---

## 3. Plugin Validation

**Status**: ✅ ALL VALID / ⚠️ SOME NEED WORK / ❌ INVALID PLUGINS

**Plugins Validated**: [count]

### Plugin: core
**Status**: ✅ READY / ⚠️ NEEDS WORK / ❌ INVALID
- Structural: [summary]
- Patterns: [summary]
- Hooks: [summary]
- Tests: [summary]

### Plugin: credo
**Status**: ✅ READY / ⚠️ NEEDS WORK / ❌ INVALID
[Similar structure]

### Plugin: ash
**Status**: ✅ READY / ⚠️ NEEDS WORK / ❌ INVALID
[Similar structure]

### Plugin: dialyzer
**Status**: ✅ READY / ⚠️ NEEDS WORK / ❌ INVALID
[Similar structure]

---

## Overall Assessment

[IF ALL PASS]
✅ **MARKETPLACE IS HEALTHY**

All quality checks passed:
- Review: Ready to push
- Tests: All passing
- Validation: All plugins valid

You're good to push!

[IF NEEDS ATTENTION]
⚠️ **ATTENTION NEEDED**

Some issues found but not critical:
- [List non-critical issues by category]

Review the detailed reports and address warnings before pushing.

[IF CRITICAL ISSUES]
❌ **DO NOT PUSH**

Critical issues detected:
- [List critical issues by category]

Fix these issues before pushing:
1. [Specific fix with file:line]
2. [Specific fix with file:line]

---

## Next Steps

[IF ALL PASS]
```bash
git push origin $(git branch --show-current)
```

[IF NEEDS ATTENTION]
1. Review detailed reports in `.thoughts/`
2. Address warnings in priority order
3. Re-run: `/qa`

[IF CRITICAL]
1. Fix critical issues listed above
2. Re-run review: `/qa review`
3. Re-run tests: `/qa test`
4. Re-run full QA: `/qa`

---

## Detailed Reports

Review:
- `.thoughts/YYYY-MM-DD-marketplace-review.md`
- `.thoughts/CHANGELOG-draft-YYYY-MM-DD.md` (if generated)

Tests:
- `.thoughts/test-marketplace-[timestamp].md`

Validation:
- See inline summaries above
```

#### 4.3 Write Consolidated Report

Generate filename: `.thoughts/YYYY-MM-DD-qa-report.md`

Write report using Write tool.

Mark fifth todo as completed: "✅ Generate consolidated QA report → completed"

### Phase 5: Present Consolidated Summary

Present concise summary to user:

```markdown
# QA Complete

**Overall**: ✅ ALL PASS / ⚠️ NEEDS ATTENTION / ❌ CRITICAL ISSUES

**Settings**: [status] - [plugin count] plugins configured [+ X added if applicable]
**Review**: [status] - [counts]
**Tests**: [status] - [passed]/[total]
**Validation**: [status] - [plugin count] plugins

**Detailed report**: `.thoughts/YYYY-MM-DD-qa-report.md`

[Next steps based on status]
```

---

## Step 2B: Execute "Review" Action

**Only execute this step if `$1` is "review".**

Follow the exact process from Step 2A, Phase 1 (Run Marketplace Review):
1. Identify changed files
2. Spawn parallel analysis agents
3. Run best practices validators
4. Synthesize review report
5. Write review document
6. Generate changelog (if appropriate)
7. Present concise summary

Present review summary to user (not consolidated report, just review results).

---

## Step 2C: Execute "Test" Action

**Only execute this step if `$1` is "test".**

Follow the exact process from Step 2A, Phase 2 (Run All Plugin Tests):

### Determine Test Scope

Plugin parameter: `$2`

- If `$2` is empty: Run ALL plugin tests
- If `$2` is provided: Run only the test for plugin `$2`

### Run Test Scripts

**For all plugins** (when `$2` is empty):
```bash
./test/run-all-tests.sh
```

**For specific plugin** (when `$2` is provided):

Check if test script exists:
```bash
test -f test/plugins/$2/test-$2-hooks.sh && echo "exists" || echo "not found"
```

If not found, list available plugins:
```bash
ls -d test/plugins/*/test-*-hooks.sh 2>/dev/null | sed 's|test/plugins/\(.*\)/test-.*|\1|'
```

Report error: "Plugin '$2' not found. Available plugins: [list]"

If found:
```bash
./test/plugins/$2/test-$2-hooks.sh
```

Capture output and exit code.

### Parse Test Output

Extract:
- Total tests run
- Tests passed
- Tests failed
- Which specific tests failed

### Generate Test Report

Create `.thoughts/` directory:
```bash
mkdir -p .thoughts && date +%Y%m%d-%H%M%S
```

Generate report (same format as Phase 2 from Step 2A).

Write to `.thoughts/test-marketplace-[timestamp].md`

### Present Results

Show concise summary:

```markdown
# Test Results Summary

**Tests Run**: [all plugins | plugin-name]

[IF ALL PASSED]
✅ All tests passed!

[IF SOME FAILED]
❌ X/Y tests failed

**Failed Tests**:
[List failed test names]

**Detailed results**: `.thoughts/test-marketplace-[timestamp].md`

To rerun tests:
- All plugins: /qa test
- Specific plugin: /qa test [plugin-name]
```

---

## Step 2D: Execute "Validate" Action

**Only execute this step if `$1` is "validate".**

Check if `$2` is provided. If empty, error: "Usage: /qa validate <plugin-name>"

Plugin parameter: `$2`

### Validate Plugin Exists

Check if plugin exists:
```bash
ls plugins/$2 2>/dev/null
```

If doesn't exist, list available:
```bash
ls plugins/
```

Report error: "Plugin '$2' not found. Available plugins: [list]"

### Fast Structural Validation

Perform automated checks:

**Directory Structure**:
- Required: `plugins/$2/`, `plugins/$2/.claude-plugin/`, `plugins/$2/.claude-plugin/plugin.json`, `plugins/$2/README.md`, `test/plugins/$2/`, `test/plugins/$2/README.md`
- Optional: `plugins/$2/hooks/hooks.json`, `plugins/$2/scripts/`

**JSON Syntax**:
```bash
jq . plugins/$2/.claude-plugin/plugin.json
jq . .claude-plugin/marketplace.json
jq . plugins/$2/hooks/hooks.json  # if exists
```

**plugin.json Fields**:
- Validate: name (matches $2), version (semver), description (not TODO), author.name, repository, license

**marketplace.json Registration**:
```bash
jq '.plugins[] | select(.name == "'$2'")' .claude-plugin/marketplace.json
```

**Script Validation** (if scripts exist):
```bash
test -x <script-path> && bash -n <script-path>
```

Report: ❌ FAIL / ⚠️ WARN / ✅ PASS for each check

### Intelligent Analysis (if structural passes)

**Only run if all structural checks passed.**

Spawn three sub-agents (Task 1 first, then Tasks 2-3 can run in parallel using Task 1's output):

**Task 1: Locate Plugin Files and Patterns** (finder):
```
Find all plugins with similar functionality to $2
Locate hooks.json and script files for $2 and similar plugins
Locate test files for $2 and similar plugins
Extract common pattern locations (stdin handling, project detection, file filtering, output formatting)
Provide file:line locations showing both $2 and comparison plugins
Do NOT read file contents - only provide file paths and pattern locations
```

Wait for Task 1 to complete, then spawn Tasks 2-3 in parallel:

**Task 2: Hook Implementation Deep Analysis** (analyzer, if hooks exist):
```
Using file paths from Task 1:
- Read plugins/$2/hooks/hooks.json
- Read scripts in plugins/$2/scripts/
For each hook:
  - Trace execution flow
  - Document stdin handling, project detection, file filtering, exit codes
  - Identify potential issues
Provide detailed technical analysis with file:line references
```

**Task 3: Test Quality Analysis** (analyzer):
```
Using test file locations from Task 1:
- Read test/plugins/$2/README.md
- Read test/plugins/$2/test-$2-hooks.sh
Compare with similar plugin test patterns from Task 1
Analyze coverage and structure
Identify missing test scenarios
Show concrete comparisons with file:line references
```

Wait for all agents to complete.

### Generate Validation Report

Synthesize findings:

```markdown
# Plugin Validation Report: $2

**Date**: [current date/time]

## Validation Summary

Overall Status: ✅ READY / ⚠️ NEEDS WORK / ❌ INVALID

Quick Stats:
- Structural Issues: X ❌ / Y ⚠️
- Pattern Deviations: X findings
- Hook Analysis: X issues / Y warnings
- Test Coverage: [assessment]

---

## Part 1: Structural Validation

[Results from structural checks]

---

## Part 2: Best Practices Analysis

**Note**: Only included if structural validation passed.

[Results from finder agent - pattern comparisons]

---

## Part 3: Hook Implementation Analysis

**Note**: Only included if plugin has hooks AND structural passed.

[Results from analyzer agent - execution flow analysis]

---

## Part 4: Test Quality Review

**Note**: Only included if structural validation passed.

[Results from finder agent - test comparison]

---

## Overall Assessment

### Strengths
[What the plugin does well]

### Areas for Improvement
[Specific issues with examples]

### Validation Criteria
✅ READY / ⚠️ NEEDS WORK / ❌ INVALID

---

## Next Steps

[IF ❌ INVALID]
Fix structural issues before proceeding

[IF ⚠️ NEEDS WORK]
Consider these improvements: [list]

[IF ✅ READY]
1. Test it: /qa test $2
2. Install it: /plugin marketplace reload && /plugin install $2@elixir
```

### Present Report

Display validation report to user.

Ask if they want:
1. Clarification on findings
2. More examples for specific patterns
3. Help fixing specific issues

---

## Important Notes

### Command Behavior
- **Default (`/qa`)**: Runs ALL quality checks (review + test all + validate all)
- **Review (`/qa review`)**: Pre-push code review only
- **Test (`/qa test [plugin]`)**: Test all or specific plugin
- **Validate (`/qa validate <plugin>`)**: Validate specific plugin

### Progress Tracking
- Use TodoWrite throughout to show progress
- Mark tasks as in_progress before starting
- Mark tasks as completed immediately after finishing
- Only ONE task in_progress at a time

### Sub-Agent Usage
- Spawn multiple agents in parallel when possible (single response, multiple Task calls)
- Marketplace review spawns 5 parallel agents: plugin/hook analysis, command/agent review, comment cleanup, version management validation, and documentation consistency validation
- Wait for ALL agents to complete before proceeding
- Use appropriate subagent types:
  - `analyzer` for execution flow and technical analysis
  - `finder` for pattern finding, examples, and documentation consistency checks
  - `comment-cleaner` for comment cleanup
  - `changelog-curator` for changelog generation

### Output
- Generate detailed reports in `.thoughts/` directory
- Present concise summaries to user
- Include file:line references for all findings
- Use severity indicators: ❌ CRITICAL / ⚠️ WARNING / 💡 RECOMMENDATION

### Quality Gates
- Review: ✅ READY TO PUSH / ⚠️ NEEDS WORK / ❌ DO NOT PUSH
- Tests: ✅ ALL PASSED / ❌ FAILURES DETECTED
- Validation: ✅ READY / ⚠️ NEEDS WORK / ❌ INVALID

### Critical Rules
- Overall status is ❌ if ANY critical issues found
- Don't run intelligent analysis if structural validation fails
- Wait for all parallel agents before synthesizing
- Save all reports to `.thoughts/` for future reference

### Documentation Consistency

Documentation consistency validation checks ALL documentation files (regardless of whether they changed) for outdated patterns that don't match the current implementation:

**Known Outdated Patterns to Check:**
- **"exit 2" for blocking**: Should now be "exit 0 with JSON permissionDecision: deny"
- **"stderr" for blocking output**: Should now be "stdout with structured JSON"
- **"Keep versions in sync"**: Should explain plugin vs marketplace versioning independence
- **Hook blocking examples**: Should show current JSON structure with permissionDecision/permissionDecisionReason/systemMessage

**Files to Validate:**
- `CLAUDE.md`: Hook Script Best Practices section, Hook Implementation Details section, Version Management section
- All `plugins/*/README.md`: Hook implementation descriptions, pattern references
- Main `README.md`: Any hook behavior or setup instructions

**Severity**: All outdated documentation is ⚠️ WARNING (doesn't block push but should be fixed to prevent confusion)

### Versioning Protocol

**Plugin Versions vs Marketplace Version**:

Plugin and marketplace versions serve different purposes and should version independently:

**When to Bump Plugin Version** (`plugins/*/.claude-plugin/plugin.json`):
- ✅ Hooks changed (hooks.json, scripts/*.sh)
- ✅ Commands added/modified (.claude/commands/*.md in plugin)
- ✅ Agents added/modified (.claude/agents/*.md in plugin)
- ✅ MCP servers changed
- ✅ Bug fixes in plugin functionality
- ✅ Documentation updates (README.md in plugin)
- Use semantic versioning:
  - **Major** (2.0.0): Breaking changes to hooks, commands, or APIs
  - **Minor** (1.1.0): New features, new commands, backward-compatible changes
  - **Patch** (1.0.1): Bug fixes, documentation updates

**When to Bump Marketplace Version** (`.claude-plugin/marketplace.json`):
- ✅ Adding new plugin to catalog
- ✅ Removing plugin from catalog
- ✅ Changing marketplace metadata (owner, description)
- ✅ Reorganizing plugin categories/structure
- ❌ NOT when updating individual plugin versions
- ❌ NOT when changing plugin functionality

**Rationale**:
- Think of it like a bookstore: book editions (plugin versions) change independently of catalog editions (marketplace version)
- Follows standard package registry practices (npm, PyPI, Homebrew)
- Users run `/plugin marketplace update` to fetch latest catalog state from Git anyway
- Marketplace version is for human tracking of catalog structural changes
