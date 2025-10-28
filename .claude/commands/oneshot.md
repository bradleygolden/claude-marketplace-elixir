---
description: Complete workflow - research, plan, implement, and validate a feature
argument-hint: [feature-description]
allowed-tools: Read, Write, Edit, Grep, Glob, Task, Bash, TodoWrite, NotebookEdit, Skill
---

# Oneshot - Complete Workflow

Execute a complete feature development workflow from research through implementation and validation.

## Overview

This command combines all workflow stages:
1. **Research** - Understand existing patterns
2. **Plan** - Create detailed implementation plan
3. **Implement** - Execute the plan
4. **QA** - Validate implementation

## Steps to Execute:

When this command is invoked, the user provides a feature description as an argument (e.g., `/oneshot Add monitoring plugin with health check hooks`).

### 1. Create Workflow Tracking

Use TodoWrite to create high-level workflow tracking:

```
1. [in_progress] Research existing patterns
2. [pending] Create implementation plan
3. [pending] Execute implementation
4. [pending] Run QA validation
5. [pending] Write workflow report
6. [pending] Present final summary
```

### 2. Research Phase

Mark first todo as in_progress.

Execute research workflow:

#### 2.1 Understand the Feature

Parse the user's feature description and identify:
- Is this a new plugin, hook modification, marketplace change, or testing enhancement?
- What similar functionality exists in the marketplace?
- What patterns should be researched?

#### 2.2 Research Existing Patterns

Spawn parallel research agents using Task tool:

**Task 1: Find Similar Implementations** (finder):
- Locate plugins with similar functionality
- Show implementation patterns
- Extract code examples with file:line references

**Task 2: Analyze Architecture** (analyzer):
- Analyze how existing implementations work
- Trace execution flows
- Document technical patterns

Wait for agents to complete.

#### 2.3 Generate Research Document

Gather metadata:
```bash
date -u +"%Y-%m-%d %H:%M:%S %Z" && git log -1 --format="%H" && git branch --show-current && git config user.name
```

Determine filename: `.thoughts/research/research-YYYY-MM-DD-[feature-name].md`

Create research document with:
- YAML frontmatter with metadata
- Research question
- Summary of findings
- Detailed findings organized by component
- Code references with file:line
- Pattern examples

Write document using Write tool.

Mark first todo as completed.

### 3. Planning Phase

Mark second todo as in_progress.

Execute planning workflow:

#### 3.1 Analyze Research Findings

Review research document to inform the plan.

#### 3.2 Create Implementation Plan

Based on research, create detailed plan including:
- Overview and prerequisites
- Architecture decisions
- Files to create/modify
- Implementation steps
- Hook implementation details
- Testing strategy
- Validation checklist

#### 3.3 Generate Plan Document

Gather metadata:
```bash
date -u +"%Y-%m-%d %H:%M:%S %Z" && git log -1 --format="%H" && git branch --show-current && git config user.name
```

Determine filename: `.thoughts/plans/plan-YYYY-MM-DD-[feature-name].md`

Create plan document with:
- YAML frontmatter (status: "draft")
- Feature description
- Implementation details
- Step-by-step instructions
- Testing approach

Write document using Write tool.

Mark second todo as completed.

### 4. Implementation Phase

Mark third todo as in_progress.

Execute implementation workflow:

#### 4.1 Load Plan

Read the plan document just created.

#### 4.2 Create Implementation Tracking

Use TodoWrite to create detailed todos from plan steps.

#### 4.3 Execute Implementation

For each step in the plan:
- Mark todo as in_progress
- Create or modify files as specified
- Follow existing patterns
- Use proper formatting and conventions
- Validate as you go (JSON syntax, script syntax)
- Mark todo as completed

#### 4.4 Update Marketplace Registration

If creating a new plugin:
- Update `.claude-plugin/marketplace.json`
- Add plugin to plugins array
- Validate JSON with jq

#### 4.5 Update Documentation

- Update marketplace README.md if needed
- Update CLAUDE.md if architecture changes
- Ensure consistency

#### 4.6 Update Plan Status

Update plan document:
- Change status from "draft" to "implemented"
- Add implementation metadata (date, commit, implementer)
- Save changes

Mark third todo as completed.

### 5. QA Validation Phase

Mark fourth todo as in_progress.

Execute QA workflow:

#### 5.1 Run Plugin Tests

If this is a new plugin or modified existing:
```bash
./test/plugins/[plugin-name]/test-[plugin-name]-hooks.sh
```

Parse test output for passes/failures.

#### 5.2 Validate JSON Structure

Validate all JSON files:
```bash
jq . .claude-plugin/marketplace.json
jq . plugins/[plugin-name]/.claude-plugin/plugin.json
jq . plugins/[plugin-name]/hooks/hooks.json
```

#### 5.3 Run Structural Validation

Verify:
- Directory structure is correct
- All required files exist
- Scripts are executable
- Documentation is complete

#### 5.4 Quick Code Review

Spawn analyzer agent to review implementation:
- Check for common issues
- Verify patterns match marketplace standards
- Validate hook implementations

Wait for agent to complete.

#### 5.5 Generate QA Report

Create summary of validation results:
- Test results
- JSON validation
- Structural validation
- Code review findings

Mark fourth todo as completed.

### 6. Write Workflow Report

Mark fifth todo as in_progress.

Create comprehensive workflow report:

1. **Create `.thoughts/` directory** if it doesn't exist
2. **Write workflow report** to `.thoughts/YYYY-MM-DD-oneshot-[feature-name].md`
3. **Include all phases**:
   - Research summary (reference .thoughts/research/ document)
   - Planning summary (reference .thoughts/plans/ document)
   - Implementation details (files created/modified, test results)
   - QA validation results (all findings)
   - Overall status and assessment
   - Next steps recommendations

Mark fifth todo as completed.

### 7. Present Final Summary

Mark sixth todo as in_progress.

Present concise summary to user:

```markdown
# Oneshot Workflow Complete

## Feature: [Feature Description]

**Status**: ✅ SUCCESS / ⚠️ NEEDS WORK / ❌ FAILED

---

## 1. Research Phase ✅

**Document**: .thoughts/research/research-YYYY-MM-DD-[feature-name].md

**Key Findings**:
- [Summary of research findings]
- [Patterns discovered]
- [Similar implementations found]

---

## 2. Planning Phase ✅

**Document**: .thoughts/plans/plan-YYYY-MM-DD-[feature-name].md

**Plan Highlights**:
- [Implementation approach]
- [Key components]
- [Testing strategy]

---

## 3. Implementation Phase ✅

**Files Created**:
- [List of new files with paths]

**Files Modified**:
- [List of modified files with paths]

**Key Changes**:
- [Summary of implementation]

---

## 4. QA Validation Phase ✅ / ⚠️ / ❌

**Test Results**: [X/Y tests passed]
**JSON Validation**: ✅ All valid / ❌ Errors found
**Structure Validation**: ✅ Complete / ⚠️ Issues found
**Code Review**: [Summary of findings]

**Issues Found** (if any):
- [List issues with severity]

---

## Next Steps

[IF ✅ SUCCESS]
Your implementation is ready! Next steps:

1. **Test in Claude Code**:
   ```bash
   /plugin marketplace reload
   /plugin install [plugin-name]@elixir
   ```

2. **Create a commit**:
   ```bash
   git add -A
   git commit -m "Add [feature-description]"
   ```

3. **Run full QA before push**:
   ```bash
   /qa
   ```

[IF ⚠️ NEEDS WORK]
Implementation complete but some issues need attention:

1. Review issues listed above
2. Fix warnings and recommendations
3. Re-run: `/qa test [plugin-name]`
4. Re-run: `/qa validate [plugin-name]`

[IF ❌ FAILED]
Implementation encountered critical issues:

1. Review error details above
2. Fix critical issues
3. Re-run failed phase:
   - Research: `/research [topic]`
   - Plan: `/plan [feature]`
   - Implement: `/implement [plan-name]`
   - QA: `/qa test [plugin-name]`

---

## Documentation

All workflow artifacts saved:

**Research**: .thoughts/research/research-YYYY-MM-DD-[feature-name].md
**Plan**: .thoughts/plans/plan-YYYY-MM-DD-[feature-name].md
**Workflow Report**: .thoughts/YYYY-MM-DD-oneshot-[feature-name].md (comprehensive audit trail)

Review these documents for complete context.
```

Mark sixth todo as completed.

## Important Notes:

### Workflow Philosophy
- This is an end-to-end automation of the complete development cycle
- Each phase builds on the previous phase's output
- All work is documented for future reference
- QA is mandatory - never skip validation

### When to Use /oneshot
- **Use when**: You want complete automation from idea to implementation
- **Use when**: You're confident in the feature description
- **Don't use when**: You want to iterate on research or planning separately
- **Don't use when**: Implementation requires user input or decisions

### Phase Dependencies
- Planning depends on research findings
- Implementation depends on plan details
- QA validates implementation quality
- Each phase's output is input to the next

### Error Handling
- If research fails: Stop and report, ask user for clarification
- If planning fails: Stop and report, may need more research
- If implementation fails: Stop and report, fix issues before QA
- If QA fails: Report issues but mark implementation complete

### Progress Tracking
- High-level TodoWrite for overall workflow
- Detailed TodoWrite during implementation phase
- Mark todos completed immediately after each phase
- Keep user informed throughout

### Alternative Approaches
If you prefer more control:
- `/research [topic]` - Just research
- `/plan [feature]` - Just planning (after research)
- `/implement [plan-name]` - Just implementation (after planning)
- `/qa` - Just validation (after implementation)

## Example Usage:

**User**: `/oneshot Add sobelow security analysis plugin`

**Process**:
1. **Research** (5-10 min):
   - Find similar plugins (credo, dialyzer)
   - Analyze security scanning patterns
   - Document findings → `.thoughts/research/research-2025-10-26-sobelow-plugin.md`

2. **Plan** (5 min):
   - Design plugin structure
   - Plan hook implementations
   - Define test strategy
   - Write plan → `.thoughts/plans/plan-2025-10-26-sobelow-plugin.md`

3. **Implement** (10-15 min):
   - Create `plugins/sobelow/` structure
   - Write plugin.json, hooks.json
   - Implement pre-commit script
   - Create test suite
   - Update marketplace.json
   - Update documentation

4. **QA** (5 min):
   - Run hook tests
   - Validate JSON
   - Check structure
   - Code review

5. **Summary**:
   - Present complete overview
   - Show all artifacts
   - Provide next steps

**Total time**: ~25-35 minutes for complete feature

## Plugin-Specific Considerations:

### New Plugin
- Research similar plugins thoroughly
- Plan complete directory structure
- Implement all required files
- Create comprehensive test suite
- Update marketplace registration

### Hook Modification
- Research existing hook behavior
- Plan backward-compatible changes
- Implement modifications carefully
- Update tests for new behavior
- Validate with existing users in mind

### Marketplace Change
- Research impact on all plugins
- Plan migration strategy if needed
- Implement changes systematically
- Validate all plugins still work

## Quality Gates:

Each phase has quality criteria:

**Research**: Comprehensive findings with concrete examples
**Planning**: Detailed, actionable plan with all files specified
**Implementation**: All files created, tests pass, JSON valid
**QA**: Tests pass, structure valid, code reviewed

Only proceed if previous phase meets quality criteria.
