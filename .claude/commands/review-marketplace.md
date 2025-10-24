---
description: Pre-push code review for marketplace changes with quality validation
argument-hint: (no arguments)
allowed-tools: Bash, Read, Glob, Write, Edit, TodoWrite, Task
---

# Review Marketplace Changes

You are conducting a **pre-push code review** for the Claude Code plugin marketplace. This review validates all staged/modified files before they are pushed to the remote branch.

## Your Role

You are a **critical quality gate** that ensures:
1. Changes follow marketplace patterns and conventions
2. Sub-agents are used appropriately in slash commands
3. Comments are critical and necessary (no fluff or obvious explanations)
4. Changes are technically correct and ready for production

## Review Process

### Phase 1: Identify Changed Files

1. Use Bash to run:
   ```bash
   git status --short && git diff --cached --name-only && git diff --name-only
   ```
2. Categorize changes by type:
   - Plugin files (plugin.json, hooks.json, scripts)
   - Slash commands (.claude/commands/*.md)
   - Sub-agent definitions (.claude/agents/*.md)
   - Tests (test/plugins/**)
   - Documentation (README.md, *.md)
   - Marketplace metadata (marketplace.json)

### Phase 2: Parallel Analysis & Cleanup

Spawn FOUR parallel sub-agent tasks using the Task tool in a single response block:

**Task 1: Plugin/Hook Changes Analysis**
Use Task tool with `subagent_type="analyzer"`:
- For each changed plugin.json, hooks.json, or script file:
  - Trace execution flow to ensure correctness
  - Verify hook matchers and patterns
  - Check for blocking vs non-blocking behavior consistency
  - Validate error handling and output formats
  - Compare with working marketplace patterns

**Task 2: Command/Agent Review**
Use Task tool with `subagent_type="finder"`:
- For each changed .claude/commands/*.md or .claude/agents/*.md:
  - Verify sub-agent usage is appropriate:
    - Are Task calls used for parallelization?
    - Is finder used for pattern finding?
    - Is analyzer used for execution tracing?
  - Check if command follows marketplace patterns
  - Validate output structure and formatting
  - Ensure TodoWrite is used for progress tracking

**Task 3: Comment Cleanup**
Use Task tool with `subagent_type="comment-cleaner"`:
- Find all files with comments in the changeset
- For EACH file with comments:
  - Read the entire file for context
  - Evaluate every comment individually
  - Remove unnecessary comments (obvious, redundant)
  - Keep critical comments (algorithms, non-obvious behavior, security, performance, integration)
  - Document all decisions (why removed/kept)
- Automatically clean up files by removing unnecessary comments
- Provide detailed report of all actions taken

**Task 4: Version Management Validation**
Use Task tool with `subagent_type="analyzer"`:
- Compare current branch with main branch to determine what actually changed
- Check version consistency:
  - If marketplace.json changed: marketplace version MUST be bumped
  - If plugin files changed: that specific plugin version MUST be bumped
  - If plugin A changed, plugin B version should NOT be bumped
  - All version bumps must be relative to main branch, not previous commits on current branch
- Validate version format (semver: X.Y.Z or X.Y.Z-rc.N)
- Check for version mismatches between related files
- Compare with main branch: `git diff main -- .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json`

Wait for ALL four agents to complete before proceeding.

### Phase 3: Best Practices Validation

After Phase 2 agents complete, validate changed files against Claude Code best practices.

**Step 1: Identify Files by Type**

Based on changed files from Phase 1, determine which validators to run:

- **Commands**: `.claude/commands/*.md` files
- **Agents**: `.claude/agents/*.md` files
- **Hooks**: `plugins/*/hooks/*.json` files
- **Scripts**: `plugins/*/scripts/*.sh` files
- **Docs**: `README.md`, `plugins/*/README.md`, `test/plugins/*/README.md` files

**Step 2: Spawn Validators in Parallel**

Spawn Task agents in parallel (single response, multiple Task calls) for each file type that has changes.
Use Task tool with `subagent_type="Explore"` for all validators:

**Task: Command Validator** (if `.claude/commands/*.md` changed)
```
Validate the following slash command files against Claude Code best practices:

Files to validate:
- [list of changed .claude/commands/*.md files]

For each file:
1. Research Claude Code slash command best practices (use your knowledge of how to fetch Claude Code docs)
2. Validate the command file against best practices
3. Check for:
   - Required YAML frontmatter (description, allowed-tools)
   - Proper TodoWrite usage for multi-step commands (3+ steps)
   - Correct tool usage (tools must be in allowed-tools)
   - Parallel vs sequential execution patterns
   - Clear step structure and instructions

Report violations with severity:
- ❌ CRITICAL (blocks push): Missing frontmatter, missing TodoWrite for multi-step, wrong tools
- ⚠️ WARNING (should fix): Poor structure, missing examples, unclear instructions
- 💡 RECOMMENDATION (optional): Improvements for clarity or maintainability

For each violation, provide:
- File path and line number
- What's wrong and why it matters
- How to fix it (if obvious)

Format output as structured markdown.
```

**Task: Agent Validator** (if `.claude/agents/*.md` changed)
```
Validate the following agent definition files against Claude Code best practices:

Files to validate:
- [list of changed .claude/agents/*.md files]

For each file:
1. Research Claude Code agent best practices (use your knowledge of how to fetch Claude Code docs)
2. Validate the agent file against best practices
3. Check for:
   - Required YAML frontmatter (name, description, allowed-tools, model)
   - Appropriate tool restrictions for specialization
   - Model selection rationale (haiku vs sonnet)
   - Clear role boundaries and responsibilities
   - Proper scope definition

Report violations with severity:
- ❌ CRITICAL: Missing frontmatter, inappropriate tool access, unclear purpose
- ⚠️ WARNING: Model selection suboptimal, scope too broad/narrow
- 💡 RECOMMENDATION: Documentation improvements

For each violation, provide file path, line number, issue, and fix.

Format output as structured markdown.
```

**Task: Hook Validator** (if `plugins/*/hooks/*.json` changed)
```
Validate the following hook files against Claude Code best practices:

Files to validate:
- [list of changed plugins/*/hooks/*.json files]

For each file:
1. Research Claude Code plugin hooks best practices (use your knowledge of how to fetch Claude Code docs)
2. Validate the hook file against best practices
3. Check for:
   - Valid JSON structure
   - Correct matcher patterns (Edit|Write, Bash, etc.)
   - Proper blocking behavior (exit codes, stderr/stdout usage)
   - Appropriate timeouts
   - stdin/stdout/stderr handling patterns
   - Context-aware execution (project detection)

Report violations with severity:
- ❌ CRITICAL: Invalid JSON, incorrect blocking pattern, missing error handling
- ⚠️ WARNING: Suboptimal timeouts, missing context awareness
- 💡 RECOMMENDATION: Improvements for robustness

For each violation, provide file path, line number, issue, and fix.

Format output as structured markdown.
```

**Task: Script Validator** (if `plugins/*/scripts/*.sh` changed)
```
Validate the following shell scripts against Claude Code best practices:

Files to validate:
- [list of changed plugins/*/scripts/*.sh files]

For each file:
1. Research Claude Code hook script best practices (use your knowledge of how to fetch Claude Code docs)
2. Validate the script against best practices
3. Check for:
   - Proper exit codes (0=success, 1=error, 2=block with feedback)
   - Correct stderr/stdout usage for blocking vs non-blocking
   - Error handling and edge cases
   - Shebang and executability
   - Function structure and naming
   - stdin input handling

Report violations with severity:
- ❌ CRITICAL: Wrong exit codes, incorrect stderr/stdout usage, missing error handling
- ⚠️ WARNING: Poor error messages, missing edge case handling
- 💡 RECOMMENDATION: Code organization improvements

For each violation, provide file path, line number, issue, and fix.

Format output as structured markdown.
```

**Task: Documentation Validator** (if README files changed)
```
Validate the following documentation files against marketplace standards:

Files to validate:
- [list of changed README.md files]

For each file:
1. Review marketplace documentation patterns from existing plugins
2. Validate the documentation against standards
3. Check for:
   - Required sections (Installation, Features, Usage)
   - Clear examples and test documentation
   - Proper markdown formatting
   - Consistency with other plugin docs
   - Completeness of information

Report violations with severity:
- ❌ CRITICAL: Missing required sections, broken examples
- ⚠️ WARNING: Incomplete sections, missing examples
- 💡 RECOMMENDATION: Clarity improvements

For each violation, provide file path, section, issue, and suggestion.

Format output as structured markdown.
```

**Step 3: Collect Validation Results**

Wait for all validators to complete, then aggregate results:

- Count total violations by severity across all validators
- Identify blocking issues (❌ CRITICAL)
- Collect warnings and recommendations

### Phase 4: Synthesize Review

Generate a comprehensive review report with:

#### 1. Executive Summary
- Total files changed: X
- Critical issues: X ❌
- Warnings: X ⚠️
- Recommendations: X 💡
- Best practices violations: X ❌ critical, X ⚠️ warnings, X 💡 recommendations
- **Overall Assessment**: ✅ READY TO PUSH / ⚠️ NEEDS WORK / ❌ DO NOT PUSH

#### 2. Changed Files by Category
List all changed files grouped by type with status indicators:
- ✅ File passes all checks
- ⚠️ File has warnings but is acceptable
- ❌ File has critical issues requiring fixes

#### 3. Plugin/Hook Changes
For each plugin/hook change:
- **File**: `path/to/file:line-range`
- **Change Type**: New feature / Bug fix / Refactor / Documentation
- **Execution Flow**: Brief summary of what changed
- **Issues Found**: List with severity (❌ Critical / ⚠️ Warning / 💡 Recommendation)
- **Comparison**: How it compares to marketplace patterns

#### 4. Command/Agent Changes
For each command/agent change:
- **File**: `path/to/file:line-range`
- **Sub-Agent Usage**: ✅ Appropriate / ⚠️ Could be improved / ❌ Incorrect
- **Pattern Compliance**: Does it follow existing command patterns?
- **Issues Found**: List with severity

#### 5. Comment Cleanup Results

Display the complete report from the comment-cleaner agent, including:

**Summary**:
- Total files processed: X
- Comments removed: X
- Comments kept: X
- Files modified: X

**Files Modified** (list each):
- file:line - Comment removed (reason)
- file:line - Comment kept (reason)

#### 6. Version Management Validation

**Version Changes Detected**:
- Marketplace: `X.Y.Z` → `X.Y.Z` (bumped/unchanged) - ✅ Correct / ❌ Should be bumped
- Plugin A: `X.Y.Z` → `X.Y.Z` (bumped/unchanged) - ✅ Correct / ❌ Should be bumped / ⚠️ Unnecessary bump
- Plugin B: `X.Y.Z` → `X.Y.Z` (unchanged) - ✅ Correct / ⚠️ Unnecessary bump

**Version Validation Against main**:
- Compared against: `git diff main -- .claude-plugin/marketplace.json plugins/*/.claude-plugin/plugin.json`
- Files changed since main: [list]
- Required version bumps: [list]
- Version format: ✅ All valid semver / ❌ Invalid format found

**Issues Found**:
- ❌ Critical: Plugin X changed but version not bumped
- ⚠️ Warning: Plugin Y version bumped but no changes detected
- ✅ All versions correct relative to main branch

#### 7. Best Practices Validation

Display results from Phase 3 validators:

**Command Validation** (if ran):
- Files validated: [list]
- Critical violations: X ❌
- Warnings: X ⚠️
- Recommendations: X 💡
- [Detailed violations from command validator]

**Agent Validation** (if ran):
- Files validated: [list]
- Critical violations: X ❌
- Warnings: X ⚠️
- Recommendations: X 💡
- [Detailed violations from agent validator]

**Hook Validation** (if ran):
- Files validated: [list]
- Critical violations: X ❌
- Warnings: X ⚠️
- Recommendations: X 💡
- [Detailed violations from hook validator]

**Script Validation** (if ran):
- Files validated: [list]
- Critical violations: X ❌
- Warnings: X ⚠️
- Recommendations: X 💡
- [Detailed violations from script validator]

**Documentation Validation** (if ran):
- Files validated: [list]
- Critical violations: X ❌
- Warnings: X ⚠️
- Recommendations: X 💡
- [Detailed violations from docs validator]

**Summary**:
- Total best practices violations: X ❌ critical, X ⚠️ warnings, X 💡 recommendations
- Status: ✅ All passed / ⚠️ Has warnings / ❌ Has critical violations

#### 8. Test Coverage
- Are there tests for new/changed functionality?
- Do existing tests need updates?
- Missing test cases?

#### 9. Documentation
- Are README files updated?
- Is CLAUDE.md updated if architecture changed?
- Are inline docs sufficient?

#### 10. Actionable Next Steps

**If ✅ READY TO PUSH**:
```bash
git push origin $(git branch --show-current)
```

**If ⚠️ NEEDS WORK** (list specific files and changes needed):
1. Fix issue in file.ext:line
2. Remove comment in file.ext:line
3. Update documentation in file.md

**If ❌ DO NOT PUSH** (list blocking issues):
1. Critical issue in file.ext:line - MUST FIX
2. Execution flow error in file.ext:line - MUST FIX
3. Best practices critical violation in file.ext:line - MUST FIX

### Phase 5: Write Review Document

After synthesizing the review report, save it to the `.thoughts/` directory for future reference.

1. **Generate review metadata:**
   ```bash
   git config user.name
   git rev-parse HEAD
   git branch --show-current
   git remote get-url origin | sed 's/.*[:/]\([^/]*\/[^/]*\)\.git/\1/'
   date -u +"%Y-%m-%dT%H:%M:%SZ"
   date +"%Y-%m-%d"
   ```

2. **Create review document filename:**
   - Format: `YYYY-MM-DD-marketplace-review.md`
   - Example: `2025-10-23-marketplace-review.md`
   - If file exists, append `-2`, `-3`, etc.

3. **Structure review document with YAML frontmatter:**
   ```markdown
   ---
   date: [Current date and time in ISO format]
   reviewer: [Git user name]
   git_commit: [Current commit hash]
   branch: [Current branch name]
   repository: [Repository name from git remote]
   review_type: pre-push
   overall_status: [READY_TO_PUSH | NEEDS_WORK | DO_NOT_PUSH]
   critical_issues: [Count]
   warnings: [Count]
   recommendations: [Count]
   bp_critical: [Count of best practices critical violations]
   bp_warnings: [Count of best practices warnings]
   bp_recommendations: [Count of best practices recommendations]
   files_changed: [Count]
   tags: [code-review, marketplace, quality-gate]
   status: complete
   last_updated: [Current date in YYYY-MM-DD format]
   last_updated_by: [Git user name]
   ---

   # Marketplace Pre-Push Code Review

   **Date**: [Current date and time]
   **Reviewer**: [Git user name]
   **Git Commit**: [Current commit hash]
   **Branch**: [Current branch name]
   **Repository**: [Repository name]

   ## Executive Summary

   - **Total files changed**: X
   - **Critical issues**: X ❌
   - **Warnings**: X ⚠️
   - **Recommendations**: X 💡
   - **Best practices violations**: X ❌ critical, X ⚠️ warnings, X 💡 recommendations
   - **Overall Assessment**: ✅ READY TO PUSH / ⚠️ NEEDS WORK / ❌ DO NOT PUSH

   [Full review content from Phase 4 - all sections 1-10]
   ```

4. **Write the review document:**
   - Use Write tool to create `.thoughts/YYYY-MM-DD-marketplace-review.md`
   - Include complete review with all sections from Phase 3
   - Ensure all file references include line numbers
   - Include complete agent reports (comment cleanup, version validation)

5. **Present concise summary to user:**
   - Show overall assessment (✅/⚠️/❌)
   - List critical issues if any
   - Show path to saved review document
   - Provide next steps based on assessment

## Critical Validation Rules

### Sub-Agent Usage (for .claude/commands/*.md files)
- ✅ Use Task tool for parallel work (research, analysis)
- ✅ Use finder for "find patterns" or "show examples"
- ✅ use analyzer for "trace execution" or "analyze implementation"
- ✅ Spawn multiple agents in single response block for parallelization
- ❌ Don't use sub-agents for simple file reads
- ❌ Don't spawn agents when direct tools (Grep, Read) are faster

### Comment Quality
- ✅ Keep: Complex algorithm explanations
- ✅ Keep: Non-obvious behavior rationale
- ✅ Keep: Security/performance trade-offs
- ❌ Remove: Obvious explanations
- ❌ Remove: Redundant docstrings
- ❌ Remove: TODO comments (convert to issues)
- ❌ Remove: Commented-out code

### Version Management
- ✅ Compare versions against main branch, not current branch history
- ✅ If marketplace.json changed: marketplace version MUST be bumped
- ✅ If plugin files changed: that specific plugin version MUST be bumped
- ✅ If plugin A changed, plugin B version should NOT be bumped (unless also changed)
- ✅ Version format must be valid semver: X.Y.Z or X.Y.Z-rc.N
- ❌ Don't bump versions based on commits within current branch
- ❌ Don't bump all plugin versions when only one changed

### Marketplace Patterns
- ✅ JSON files are valid (check with jq)
- ✅ Hooks follow matcher patterns (Edit|Write, Bash, etc.)
- ✅ Scripts are executable and have proper shebangs
- ✅ File paths use {{file_path}} template variables
- ✅ Blocking hooks exit 2 on stderr, non-blocking use additionalContext
- ✅ Plugins registered in marketplace.json
- ✅ Tests exist in test/plugins/<plugin-name>/

## Output Requirements

- **Be thorough but concise** - focus on issues, not perfect code
- **Use file:line references** for every issue/example
- **Be non-judgmental** - compare with patterns, don't critique style
- **Provide context** - show marketplace examples for comparison
- **Give clear guidance** - user should know exactly what to do next
- **Use severity indicators** consistently:
  - ❌ Critical (blocks push)
  - ⚠️ Warning (should fix but not blocking)
  - 💡 Recommendation (nice to have)

## Progress Tracking

Use TodoWrite throughout to track:
1. Identifying changed files
2. Spawning four parallel agents (analyzer, finder, comment-cleaner, version validator)
3. Waiting for all agent results
4. Spawning best practices validators (based on changed file types)
5. Waiting for validator results
6. Synthesizing review report (includes all analysis, cleanup, and validation)
7. Writing review document to .thoughts/ directory
8. Presenting concise summary to user

## Important Notes

- This is a **quality gate**, not a refactoring session
- Focus on **correctness** and **patterns**, not style preferences
- **Do not suggest fixes** unless they're obvious from marketplace patterns
- **Do not rewrite code** - only identify issues
- Remember: comments should explain **WHY**, not **WHAT**
- The **comment-cleaner agent** will automatically remove unnecessary comments during review
- The **version validator** ensures versions are bumped correctly relative to main branch
- The **best practices validators** check all changed files against Claude Code standards
- **Critical best practices violations BLOCK the push** - treat them as seriously as other critical issues
- **Review documents are saved** to `.thoughts/` directory for future reference
- Present a **concise summary** to the user; full details are in the saved review document
- The user will push if you give ✅ READY TO PUSH - be thorough!
- Overall status logic: ❌ DO NOT PUSH if (critical_issues > 0 OR bp_critical > 0)
