---
description: Create detailed implementation plans for plugin development
argument-hint: [feature-description]
allowed-tools: Read, Grep, Glob, Task, Bash, TodoWrite, Write, Skill
---

# Plan

You are tasked with creating detailed implementation plans for plugin marketplace features, modifications, or new plugin development.

## Steps to Execute:

When this command is invoked, the user provides a feature description as an argument (e.g., `/plan Add monitoring plugin with health check hooks`). Begin planning immediately.

1. **Understand the requirement:**
   - Parse the user's feature description
   - Identify if this is: new plugin, hook modification, marketplace change, or testing enhancement
   - Ask clarifying questions if the request is ambiguous using AskUserQuestion

2. **Research existing patterns:**
   - Use Task agents to research similar implementations:
     - finder: "Find similar plugins or hooks in the marketplace"
     - analyzer: "Analyze how existing plugins implement similar features"
   - Review relevant test patterns in test/plugins/
   - Check marketplace.json structure and plugin registration patterns
   - Examine hook patterns in existing plugins/*/hooks/hooks.json files

3. **Create implementation plan:**
   - Break down the feature into discrete, testable steps
   - Identify all files that need creation or modification
   - Plan hook definitions (PostToolUse/PreToolUse, blocking/non-blocking)
   - Design script implementations with proper exit codes and JSON output
   - Plan test scenarios for hook validation
   - Consider JSON schema validation requirements

4. **Structure the plan document:**
   - Use TodoWrite to track planning steps
   - Create a comprehensive plan with sections:
     - Overview
     - Prerequisites
     - Implementation Steps
     - File Changes (create/modify)
     - Testing Strategy
     - Validation Checklist

5. **Gather metadata:**
   - Get current date/time: `date -u +"%Y-%m-%d %H:%M:%S %Z"`
   - Get git info: `git log -1 --format="%H" && git branch --show-current && git config user.name`
   - Determine filename: `docs/plans/plan-YYYY-MM-DD-feature-name.md`
     - Format: `docs/plans/plan-YYYY-MM-DD-feature-name.md` where:
       - YYYY-MM-DD is today's date
       - feature-name is a brief kebab-case description
     - Examples:
       - `docs/plans/plan-2025-10-26-monitoring-plugin.md`
       - `docs/plans/plan-2025-10-26-hook-timeout-support.md`
       - `docs/plans/plan-2025-10-26-parallel-hook-execution.md`

6. **Write the plan document:**
   - Create file at determined path with structure:

```markdown
---
date: [Current date and time in ISO format]
planner: [Git user name]
commit: [Current commit hash]
branch: [Current branch name]
repository: [Repository name from git remote]
feature: "[Feature Description]"
tags: [plan, plugin-development, relevant-topics]
status: draft
---

# Plan: [Feature Description]

**Date**: [Current date and time]
**Planner**: [Git user name]
**Git Commit**: [Current commit hash]
**Branch**: [Current branch name]
**Repository**: [Repository name]

## Overview

[High-level description of what this plan accomplishes]

## Prerequisites

- [ ] Research existing patterns (link to research docs if available)
- [ ] Identify required dependencies
- [ ] Review marketplace constraints
- [ ] Check plugin namespace availability (for new plugins)

## Implementation Type

[Check one: New Plugin | Hook Modification | Marketplace Change | Testing Enhancement]

## Architecture Decisions

### Plugin Structure (for new plugins)
- Plugin name: `[name]`
- Namespace: `[name]@elixir`
- Hook types: [PostToolUse/PreToolUse]
- Blocking behavior: [Yes/No and why]

### Hook Design (for hook changes)
- Hook event: [PostToolUse/PreToolUse]
- Tool matcher: [Edit|Write|Bash pattern]
- Blocking: [Yes/No]
- Output pattern: [additionalContext/permissionDecision]

### Files to Create

1. **Plugin metadata** (for new plugins)
   - `plugins/[name]/.claude-plugin/plugin.json`
   - Fields: name, version, description, author, hooks

2. **Hook definitions**
   - `plugins/[name]/hooks/hooks.json`
   - Hook configurations with matchers and commands

3. **Hook scripts**
   - `plugins/[name]/scripts/[hook-name].sh`
   - Implementation with proper exit codes and JSON output

4. **Documentation**
   - `plugins/[name]/README.md`
   - Plugin features, installation, and usage

5. **Tests**
   - `test/plugins/[name]/test-[name]-hooks.sh`
   - Hook validation test suite
   - Test directories with fixtures

### Files to Modify

1. **Marketplace registration** (for new plugins)
   - `.claude-plugin/marketplace.json`
   - Add plugin to plugins array

2. **Existing hooks** (for hook modifications)
   - `plugins/[name]/hooks/hooks.json`
   - Update hook definitions

3. **Documentation updates**
   - `README.md`
   - `CLAUDE.md`
   - Plugin-specific README.md

## Implementation Steps

### Step 1: [Phase Name]
**Files**: [List of files]
**Actions**:
- [ ] [Specific action with file references]
- [ ] [Specific action with file references]

**Implementation details**:
```[language]
// Code structure or pseudocode
```

### Step 2: [Phase Name]
[Continue for each implementation phase]

## Hook Implementation Details

### Hook 1: [Hook Name]
**Type**: [PostToolUse/PreToolUse]
**Matcher**: `[tool matcher regex]`
**Blocking**: [Yes/No]
**Script**: `plugins/[name]/scripts/[script-name].sh`

**Exit code behavior**:
- `0`: Success [describe what happens]
- `1`: Error [describe what happens]

**JSON output pattern**:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse|PreToolUse",
    "additionalContext": "..." | "permissionDecision": "allow|deny",
    "permissionDecisionReason": "..." (if blocking)
  },
  "systemMessage": "..." (optional)
}
```

**Script logic**:
1. Extract tool parameters with jq
2. Filter by file type/command
3. Execute validation/analysis
4. Generate appropriate JSON output
5. Exit with correct code

## Testing Strategy

### Unit Tests (hook validation)
- Test file in: `test/plugins/[name]/test-[name]-hooks.sh`
- Test scenarios:
  - [ ] Hook triggers on correct tool/file type
  - [ ] Hook ignores non-matching tools/files
  - [ ] Blocking hooks return correct permissionDecision
  - [ ] Non-blocking hooks return additionalContext
  - [ ] Exit codes are correct
  - [ ] JSON output is well-formed

### Integration Tests
- [ ] Plugin installs correctly
- [ ] Hooks execute in Claude Code
- [ ] Multiple hooks don't conflict
- [ ] Performance is acceptable

### Manual Testing
- [ ] Test in real Claude Code session
- [ ] Verify blocking behavior
- [ ] Check context passing
- [ ] Validate user experience

## Validation Checklist

### JSON Structure
- [ ] marketplace.json is valid JSON (jq validation)
- [ ] plugin.json is valid JSON (jq validation)
- [ ] hooks.json is valid JSON (jq validation)
- [ ] All required fields present

### Plugin Structure
- [ ] Required directories exist
- [ ] plugin.json has all metadata
- [ ] hooks.json references valid scripts
- [ ] Scripts are executable
- [ ] README.md is comprehensive

### Documentation
- [ ] Plugin README.md complete
- [ ] Marketplace README.md updated
- [ ] CLAUDE.md updated (if needed)
- [ ] Usage examples provided
- [ ] Hook behavior documented

### Testing
- [ ] Test suite exists
- [ ] All tests pass
- [ ] Test coverage is adequate
- [ ] Edge cases covered

## Dependencies

[List any dependencies on other plugins, external tools, or system requirements]

## Risks and Considerations

[Identify potential issues, edge cases, or limitations]

## Future Enhancements

[Optional improvements or features to consider later]

## Implementation Timeline

[Optional: rough estimate of implementation phases]

## References

[Links to related research docs, existing plugins, or external documentation]
```

7. **Present the plan:**
   - Show user a summary of the plan
   - Highlight key implementation steps
   - Ask if they want to proceed with implementation or modify the plan
   - Inform them they can use `/implement [plan-name]` to execute the plan

## Plugin-Specific Planning Considerations:

### New Plugin Planning
- Plugin name and namespace
- Hook event types (PostToolUse/PreToolUse)
- Blocking vs non-blocking behavior
- Tool matchers (Edit/Write/Bash patterns)
- File type filters (.ex, .exs, etc.)
- Command filters (git commit, mix commands, etc.)
- Exit code handling
- JSON output patterns
- Test scenarios

### Hook Modification Planning
- Impact on existing functionality
- Backward compatibility
- Hook execution order
- Performance implications
- User experience changes

### Marketplace Changes
- Version bumping strategy
- Plugin registration updates
- Namespace management
- Breaking changes

### Testing Enhancements
- Test framework updates
- New test patterns
- Coverage improvements
- CI/CD integration

## Important Notes:

- Plans should be detailed enough to implement without research
- Include specific file paths and code structures
- Consider the full plugin lifecycle: development, testing, documentation, release
- Think about edge cases and error scenarios
- Plan for comprehensive testing from the start
- Follow existing patterns in the marketplace
- Use TodoWrite to track planning progress
- Plans are living documents that can be updated during implementation

## Example Usage:

**User**: `/plan` then "Add sobelow security analysis plugin"

**Process**:
1. Research existing plugins (credo, dialyzer) for patterns
2. Analyze security scanning workflows
3. Create plan for:
   - plugins/sobelow/.claude-plugin/plugin.json
   - plugins/sobelow/hooks/hooks.json
   - plugins/sobelow/scripts/pre-commit-check.sh
   - plugins/sobelow/README.md
   - test/plugins/sobelow/test-sobelow-hooks.sh
4. Define hook behavior (PreToolUse blocking on git commit)
5. Plan test scenarios
6. Write comprehensive plan document
7. Present plan summary

**User**: "Modify the core plugin to support custom format options"

**Process**:
1. Research current auto-format hook implementation
2. Analyze plugins/core/hooks/hooks.json and scripts
3. Plan modifications to:
   - Hook script to read .formatter.exs
   - Pass custom options to mix format
   - Handle format failures gracefully
4. Plan testing updates
5. Write plan document
6. Present modifications summary
