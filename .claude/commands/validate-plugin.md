---
description: Validate a plugin implementation with intelligent analysis
argument-hint: <plugin-name>
allowed-tools: Bash, Read, Glob, Grep, TodoWrite, Task
---

# Validate Plugin Command

This command validates a plugin implementation to ensure it follows marketplace guidelines, using both automated checks and intelligent sub-agent analysis.

## Usage

```
/validate-plugin <plugin-name>
```

## Overview

This validation performs:
1. **Fast structural checks** - Directory structure, JSON syntax, file existence
2. **Intelligent analysis** - Pattern comparison, hook analysis, test quality review
3. **Actionable feedback** - Specific examples and recommendations for improvement

## Instructions

### Step 1: Validate Plugin Exists

Check if the plugin exists:
```bash
ls .claude-plugin/plugins/<plugin-name> 2>/dev/null
```

If it doesn't exist, report error and list available plugins:
```bash
ls .claude-plugin/plugins/
```

### Step 2: Create Validation Plan

Use TodoWrite to track validation progress:

```
✅ Fast structural validation (automated)
⏳ Best practices analysis (finder)
⏳ Hook implementation analysis (analyzer)
⏳ Test quality review (finder)
⏳ Final report synthesis
```

### Step 3: Fast Structural Validation

Perform quick automated checks:

#### 3.1 Directory Structure

**Required files/directories:**
- `.claude-plugin/plugins/<plugin-name>/`
- `.claude-plugin/plugins/<plugin-name>/.claude-plugin/`
- `.claude-plugin/plugins/<plugin-name>/.claude-plugin/plugin.json`
- `.claude-plugin/plugins/<plugin-name>/README.md`
- `test/<plugin-name>/`
- `test/<plugin-name>/README.md`

**Optional (note if present):**
- `.claude-plugin/plugins/<plugin-name>/hooks/hooks.json`
- `.claude-plugin/plugins/<plugin-name>/scripts/`

Report:
- ❌ FAIL if required files missing
- ℹ️ INFO if optional components present

#### 3.2 JSON Syntax Validation

Validate all JSON files:
```bash
jq . .claude-plugin/plugins/<plugin-name>/.claude-plugin/plugin.json
jq . .claude-plugin/marketplace.json
# If hooks exist:
jq . .claude-plugin/plugins/<plugin-name>/hooks/hooks.json
```

Report:
- ❌ FAIL if any JSON is invalid
- ✅ PASS if all JSON is valid

#### 3.3 plugin.json Field Validation

Read and validate required fields:
- `name` (must match `<plugin-name>`)
- `version` (must follow semver)
- `description` (must not be "TODO: Add plugin description")
- `author.name` (must exist)
- `repository` (must be a string)
- `license` (must be a string)

Report:
- ❌ FAIL if required field missing or invalid
- ⚠️ WARN if TODO placeholder present

#### 3.4 marketplace.json Registration

Check if plugin is registered:
```bash
jq '.plugins[] | select(.name == "<plugin-name>")' .claude-plugin/marketplace.json
```

Validate entry has:
- `name` matches `<plugin-name>`
- `source` equals `./plugins/<plugin-name>`
- All required fields present

Report:
- ❌ FAIL if not registered or incorrect
- ✅ PASS if properly registered

#### 3.5 Script Validation (if scripts exist)

For each `.sh` file in `scripts/`:
```bash
# Check executable
test -x <script-path>
# Check syntax
bash -n <script-path>
```

Report:
- ❌ FAIL if not executable or syntax errors
- ✅ PASS if valid

### Step 4: Intelligent Sub-Agent Analysis

**CRITICAL**: If structural validation has any ❌ FAIL results, skip this step and proceed directly to Step 5 (Final Report). Only run intelligent analysis if structure is valid.

After basic structural checks pass, spawn parallel sub-agents for deep analysis using the Task tool:

#### Task 1: Best Practices Pattern Analysis

Use TodoWrite to update: "⏳ Best practices analysis (finder) → in progress"

Use Task tool with `subagent_type="finder"`:

```
Use Task tool with subagent_type="finder" to perform best practices analysis for <plugin-name>:

1. Find all plugins in the marketplace with similar functionality or hook types
2. Extract common patterns used across the marketplace:
   - Stdin handling patterns
   - Project root detection approaches
   - File filtering methods
   - Output formatting patterns
3. Compare <plugin-name>'s implementation against these patterns
4. For each difference found, provide:
   - What <plugin-name> does (file:line reference)
   - What the common pattern is (file:line examples from other plugins)
   - Specific code examples showing both approaches

Focus on documentation, not criticism. Show what patterns exist in the marketplace.

Return findings organized by pattern type with concrete code examples.
```

#### Task 2: Hook Implementation Deep Analysis (if hooks exist)

**Only run if** plugin has hooks defined.

Use TodoWrite to update: "⏳ Hook implementation analysis (analyzer) → in progress"

Use Task tool with `subagent_type="analyzer"`:

```
Use Task tool with subagent_type="analyzer" to deeply analyze <plugin-name>'s hook implementations:

1. Read the hooks.json file and any external scripts
2. For EACH hook defined:
   - Trace the complete execution flow from stdin to output
   - Document how it handles stdin (jq queries, variable extraction)
   - Verify project root detection implementation
   - Check file type filtering logic
   - Verify exit code usage (0 for success, 2 for blocking)
   - Identify error handling approach
3. For each hook, document:
   - Current implementation details with file:line references
   - How data flows through the hook
   - Any potential issues with the implementation (missing checks, incorrect patterns)

Focus on documenting HOW the hooks work, not evaluating if they're good or bad.

Return a detailed technical analysis with precise file:line references.
```

#### Task 3: Test Quality Comparison

Use TodoWrite to update: "⏳ Test quality review (finder) → in progress"

Use Task tool with `subagent_type="finder"`:

```
Use Task tool with subagent_type="finder" to compare <plugin-name>'s test suite against marketplace test patterns:

1. Read test/<plugin-name>/README.md
2. Find test suites for all other plugins in the marketplace
3. Compare test coverage and structure:
   - Does <plugin-name> test all hooks?
   - Does it include setup/teardown?
   - Does it test edge cases (missing mix.exs, invalid input)?
   - Does it verify expected behavior clearly?
4. Identify any test patterns used by other plugins that <plugin-name> doesn't use
5. Show concrete examples from other plugins' test suites

Focus on showing what test patterns exist, not judging quality.

Return findings with specific examples from test/*/README.md files.
```

### Step 5: Wait for All Agents and Synthesize

**CRITICAL**: Wait for ALL sub-agent tasks to complete before proceeding.

Use TodoWrite to mark each completed task:
- ✅ Best practices analysis (finder) → completed
- ✅ Hook implementation analysis (analyzer) → completed
- ✅ Test quality review (finder) → completed
- ⏳ Final report synthesis → in progress

### Step 6: Generate Comprehensive Validation Report

Synthesize all findings into a comprehensive report:

```markdown
# Plugin Validation Report: <plugin-name>

**Date**: [current date/time]
**Validator**: Claude Code Validation System

## Validation Summary

Overall Status: ✅ READY / ⚠️ NEEDS WORK / ❌ INVALID

Quick Stats:
- Structural Issues: X ❌ / Y ⚠️
- Pattern Deviations: X findings
- Hook Analysis: X issues / Y warnings
- Test Coverage: [assessment]

---

## Part 1: Structural Validation (Automated Checks)

### Directory Structure
✅/❌ All required files present
ℹ️ Optional components: [list what exists]

### JSON Validation
✅/❌ plugin.json: [status]
✅/❌ marketplace.json: [status]
✅/❌ hooks.json: [status] (if applicable)

### Metadata Validation
✅/❌ Plugin name matches
✅/❌ Version follows semver
⚠️/✅ Description is not placeholder
✅/❌ Required fields present

### Registration
✅/❌ Properly registered in marketplace.json
✅/❌ Source path correct

### Scripts (if present)
✅/❌ All scripts executable
✅/❌ All scripts have valid syntax

---

## Part 2: Best Practices Analysis (finder)

**Note**: Only include this section if all structural checks in Part 1 passed (no ❌ INVALID results). If structural validation failed, skip directly to "Next Steps" section with instructions to fix structural issues first.

### Stdin Handling Patterns

**Finding**: Your plugin uses [pattern description]

**Your Implementation**:
```
File: .claude-plugin/plugins/<plugin-name>/hooks/hooks.json:X
[code snippet]
```

**Marketplace Standard** (used by X/Y plugins):
```
File: .claude-plugin/plugins/[example]/hooks/hooks.json:X
[code snippet from another plugin]
```

**Recommendation**: [if different] Consider aligning with the marketplace pattern for consistency.

### Project Root Detection

**Finding**: [comparison]

**Your Implementation**:
```
[code with file:line]
```

**Common Pattern**:
```
[code example from other plugins]
```

### [Other Pattern Categories]

[Similar structure for each pattern type found]

---

## Part 3: Hook Implementation Analysis (analyzer)

**Note**: Only include this section if the plugin has hooks AND all structural checks in Part 1 passed. If no hooks exist or structural validation failed, skip this section.

### Hook 1: [Hook Name]

**Type**: PostToolUse / PreToolUse
**Location**: [file:line]

**Execution Flow Analysis**:
1. [Step-by-step trace]
2. [Data transformations]
3. [Output handling]

**Implementation Details**:
- Stdin handling: [how it works]
- Project detection: [how it works]
- File filtering: [how it works]
- Exit code: [how it works]

**Observations**:
- ✅ [What works correctly]
- ⚠️ [Potential improvements with examples]

**Example Reference**:
See similar implementation in [plugin-name] at [file:line]

### [Repeat for each hook]

---

## Part 4: Test Quality Review (finder)

**Note**: Only include this section if all structural checks in Part 1 passed. If structural validation failed, skip this section.

### Test Coverage Assessment

**Your Test Suite**: test/<plugin-name>/README.md

**Coverage**:
- ✅/❌ Tests for each hook
- ✅/❌ Setup/teardown included
- ✅/❌ Edge cases tested
- ✅/❌ Success criteria clearly defined

**Comparison with Marketplace**:

Similar plugins and their test approaches:
```
[plugin-1]: test/[plugin-1]/README.md
- Includes: [features]
- Example: [specific test pattern]

[plugin-2]: test/[plugin-2]/README.md
- Includes: [features]
- Example: [specific test pattern]
```

**Missing Test Scenarios** (if any):
- [Scenario 1] - See example in test/[plugin]/README.md:X
- [Scenario 2] - See example in test/[plugin]/README.md:Y

---

## Overall Assessment

### Strengths
- [List what the plugin does well]
- [Reference specific implementations]

### Areas for Improvement
1. **[Category]**: [Specific issue]
   - Current: [file:line reference]
   - Suggested: [pattern to follow]
   - Example: [file:line from another plugin]

2. **[Category]**: [Specific issue]
   - [Similar structure]

### Validation Criteria

**✅ READY**: No structural failures, patterns align with marketplace
**⚠️ NEEDS WORK**: Valid structure, but patterns differ from marketplace standards
**❌ INVALID**: Structural failures prevent plugin from working

---

## Next Steps

[IF ❌ INVALID]
Fix the following structural issues before proceeding:
- [List ❌ failures]

[IF ⚠️ NEEDS WORK]
Your plugin will work, but consider these improvements:
1. [Specific actionable item with example]
2. [Specific actionable item with example]

[IF ✅ READY]
Your plugin follows marketplace standards! You can:
1. Test it: /test-marketplace <plugin-name>
2. Install it: /plugin marketplace reload && /plugin install <plugin-name>@elixir

---

## Reference Files

Plugin files analyzed:
- `.claude-plugin/plugins/<plugin-name>/.claude-plugin/plugin.json`
- `.claude-plugin/plugins/<plugin-name>/hooks/hooks.json` (if exists)
- `.claude-plugin/plugins/<plugin-name>/scripts/*.sh` (if exist)
- `.claude-plugin/plugins/<plugin-name>/README.md`
- `test/<plugin-name>/README.md`
- `.claude-plugin/marketplace.json` (entry)

Marketplace plugins referenced for comparison:
- [List plugins that were used as examples]
```

### Step 7: Present Report

Use TodoWrite to mark: ✅ Final report synthesis → completed

Present the comprehensive validation report to the user.

Ask if they:
1. Want clarification on any findings
2. Want to see more examples for specific patterns
3. Want help fixing specific issues

## Important Notes

- **Two-Phase Validation**: Fast checks first, then intelligent analysis
- **Skip intelligent analysis if structural fails**: Don't waste time analyzing broken structure
- **Parallel execution**: Spawn all 3 sub-agents simultaneously for speed
- **Wait for completion**: Don't synthesize until all agents return
- **Actionable feedback**: Always include file:line examples
- **No judgment**: Present findings as "different from patterns" not "wrong"
- **Specific examples**: Every recommendation should show code from another plugin

## Validation Philosophy

This validation:
- ✅ Documents how your plugin compares to marketplace patterns
- ✅ Shows concrete examples from successful plugins
- ✅ Provides actionable guidance with file references
- ❌ Does NOT judge if your approach is "right" or "wrong"
- ❌ Does NOT force you to change working implementations
- ❌ Does NOT criticize design decisions

The goal is to help you understand marketplace conventions and make informed decisions about alignment.
