# Plugin Marketplace Development Workflows

**Generated**: 2025-10-26 20:16:03 UTC
**Author**: Bradley Golden
**Version**: 1.0.0

This document provides a complete guide to the development workflows available in this Claude Code plugin marketplace project.

---

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Workflow Commands](#workflow-commands)
  - [/research](#research---explore-and-document)
  - [/plan](#plan---design-implementation)
  - [/implement](#implement---execute-plan)
  - [/qa](#qa---validate-quality)
  - [/oneshot](#oneshot---complete-workflow)
- [Workflow Patterns](#workflow-patterns)
- [Best Practices](#best-practices)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

---

## Overview

This marketplace uses a structured workflow approach for plugin development:

```
┌──────────┐     ┌──────┐     ┌───────────┐     ┌────┐
│ Research │ ──> │ Plan │ ──> │ Implement │ ──> │ QA │
└──────────┘     └──────┘     └───────────┘     └────┘
     │              │              │              │
     └──────────────┴──────────────┴──────────────┘
                    /oneshot
```

### Workflow Stages

1. **Research** - Explore codebase patterns and document findings
2. **Plan** - Create detailed implementation plans
3. **Implement** - Execute plans with verification
4. **QA** - Validate quality through comprehensive testing

### Design Philosophy

- **Documentation-First**: Every workflow generates documentation
- **Pattern-Based**: Learn from existing implementations
- **Automated Validation**: Quality checks at every stage
- **Traceable**: All artifacts saved for future reference

---

## Quick Start

### For New Plugin Development

```bash
# 1. Research existing patterns
/research "How do plugins with pre-commit hooks work?"

# 2. Create implementation plan
/plan "Add monitoring plugin with health check hooks"

# 3. Execute the plan
/implement monitoring-plugin

# 4. Validate implementation
/qa test monitoring
/qa validate monitoring
```

### For Quick Development

```bash
# Run complete workflow in one command
/oneshot "Add monitoring plugin with health check hooks"
```

### For Maintenance

```bash
# Research existing implementation
/research "How does the credo plugin handle file filtering?"

# Validate all plugins
/qa

# Test specific plugin
/qa test core
```

---

## Workflow Commands

### /research - Explore and Document

**Purpose**: Explore the codebase to understand patterns, implementations, and architecture.

**Usage**:
```bash
/research [research-query]
```

**What It Does**:
1. Spawns parallel research agents (finder, analyzer)
2. Explores relevant files and patterns
3. Documents findings with file:line references
4. Generates research document in `docs/research/`

**Examples**:
```bash
/research "How do PostToolUse hooks work?"
/research "What patterns do blocking hooks use?"
/research "How is the marketplace.json structured?"
/research "How are hook tests implemented?"
```

**Output**:
- Research document: `docs/research/research-YYYY-MM-DD-[topic].md`
- YAML frontmatter with metadata
- Detailed findings organized by component
- Code references with file:line numbers
- Pattern examples

**Plugin Marketplace Focus**:
- Marketplace structure and plugin metadata
- Hook patterns (PostToolUse/PreToolUse, blocking/non-blocking)
- Test infrastructure and validation
- Script patterns and JSON output
- Documentation standards

**Best For**:
- Understanding existing implementations
- Learning marketplace patterns
- Investigating how features work
- Documenting codebase knowledge

---

### /plan - Design Implementation

**Purpose**: Create detailed implementation plans for new features or modifications.

**Usage**:
```bash
/plan [feature-description]
```

**What It Does**:
1. Researches similar implementations
2. Analyzes existing patterns
3. Creates comprehensive implementation plan
4. Documents all files to create/modify
5. Defines testing strategy

**Examples**:
```bash
/plan "Add sobelow security analysis plugin"
/plan "Modify core plugin to support custom format options"
/plan "Add parallel hook execution support"
/plan "Enhance test framework with better reporting"
```

**Output**:
- Plan document: `docs/plans/plan-YYYY-MM-DD-[feature].md`
- YAML frontmatter (status: draft)
- Architecture decisions
- Step-by-step implementation guide
- File creation/modification list
- Testing strategy and validation checklist

**Plan Includes**:
- **Overview**: High-level description
- **Prerequisites**: Research and dependencies
- **Implementation Type**: New plugin, hook modification, etc.
- **Architecture Decisions**: Plugin structure, hook design
- **Implementation Steps**: Detailed phases with code
- **Hook Implementation Details**: Exit codes, JSON patterns
- **Testing Strategy**: Unit, integration, manual tests
- **Validation Checklist**: JSON, structure, documentation, tests

**Best For**:
- Planning new plugins
- Designing hook modifications
- Preparing marketplace changes
- Organizing complex features

---

### /implement - Execute Plan

**Purpose**: Implement features according to a detailed plan document.

**Usage**:
```bash
/implement [plan-name]
/implement              # Lists available plans
```

**What It Does**:
1. Loads plan document from `docs/plans/`
2. Creates implementation tracking with TodoWrite
3. Executes each step sequentially
4. Validates JSON and scripts as it goes
5. Runs tests after implementation
6. Updates marketplace registration
7. Updates documentation
8. Updates plan status to "implemented"

**Examples**:
```bash
/implement monitoring-plugin
/implement sobelow-plugin
/implement custom-format-options
```

**Implementation Process**:
1. Parse plan document
2. Create todos for each step
3. Create plugin metadata files
4. Implement hook definitions
5. Write hook scripts
6. Create documentation
7. Build test suite
8. Run JSON validation
9. Execute hook tests
10. Update plan status

**Validation During Implementation**:
- JSON syntax: `jq . file.json`
- Script syntax: `bash -n script.sh`
- File structure verification
- Test execution

**Best For**:
- Executing planned features
- Following structured implementation
- Ensuring nothing is missed
- Maintaining quality throughout

---

### /qa - Validate Quality

**Purpose**: Comprehensive quality assurance for the marketplace.

**Usage**:
```bash
/qa                      # Run everything (review + validate all + test all)
/qa review               # Pre-push code review only
/qa test                 # Test all plugins
/qa test [plugin-name]   # Test specific plugin
/qa validate <plugin-name>  # Validate specific plugin structure
```

**What It Does**:

**Default (`/qa`)** - Runs ALL quality checks:
1. Validates settings.json plugin configuration
2. Runs marketplace code review
3. Tests all plugins
4. Validates all plugin structures
5. Generates consolidated QA report

**Review (`/qa review`)** - Pre-push validation:
1. Identifies changed files
2. Spawns parallel analysis agents
3. Validates best practices
4. Checks documentation consistency
5. Validates version management
6. Generates changelog

**Test (`/qa test [plugin]`)** - Hook testing:
1. Runs test suite for all or specific plugin
2. Validates exit codes and JSON output
3. Checks file type filtering
4. Verifies blocking behavior

**Validate (`/qa validate <plugin>`)** - Structure validation:
1. Fast structural validation (JSON, files, scripts)
2. Best practices pattern analysis
3. Hook implementation deep analysis
4. Test quality comparison

**Examples**:
```bash
# Before pushing changes
/qa

# Review changes only
/qa review

# Test all plugins
/qa test

# Test specific plugin
/qa test core
/qa test credo

# Validate plugin structure
/qa validate ash
/qa validate dialyzer
```

**Quality Checks**:
- **JSON Validation**: marketplace.json, plugin.json, hooks.json
- **Structure Audit**: Required directories and files
- **Hook Validation**: Exit codes, JSON output, blocking behavior
- **Documentation**: README completeness, pattern consistency
- **Tests**: Hook test suites, coverage, patterns
- **Best Practices**: Code quality, patterns, conventions

**Output**:
- Consolidated report: `.thoughts/YYYY-MM-DD-qa-report.md`
- Review report: `.thoughts/YYYY-MM-DD-marketplace-review.md`
- Test results: `.thoughts/test-marketplace-[timestamp].md`
- Changelog draft: `.thoughts/CHANGELOG-draft-YYYY-MM-DD.md`

**Quality Gates**:
- ✅ **READY TO PUSH**: All checks passed
- ⚠️ **NEEDS ATTENTION**: Warnings found
- ❌ **DO NOT PUSH**: Critical issues detected

**Best For**:
- Pre-push validation
- Continuous quality checks
- Plugin structure verification
- Ensuring marketplace health

---

### /oneshot - Complete Workflow

**Purpose**: Execute complete feature development from research through QA.

**Usage**:
```bash
/oneshot [feature-description]
```

**What It Does**:
1. **Research Phase**: Understand existing patterns
2. **Planning Phase**: Create detailed implementation plan
3. **Implementation Phase**: Execute the plan
4. **QA Phase**: Validate implementation

**Examples**:
```bash
/oneshot "Add monitoring plugin with health check hooks"
/oneshot "Implement custom formatter configuration support"
/oneshot "Add security scanning with sobelow"
```

**Complete Workflow**:

**Phase 1: Research** (~5-10 min)
- Spawns parallel finder and analyzer agents
- Documents existing patterns
- Generates research document

**Phase 2: Planning** (~5 min)
- Analyzes research findings
- Creates implementation plan
- Defines testing strategy

**Phase 3: Implementation** (~10-15 min)
- Executes plan step-by-step
- Creates all files
- Runs validation
- Updates documentation

**Phase 4: QA** (~5 min)
- Runs plugin tests
- Validates JSON structure
- Performs structural validation
- Quick code review

**Total Time**: ~25-35 minutes for complete feature

**Output**:
- Research document: `docs/research/research-YYYY-MM-DD-[feature].md`
- Plan document: `docs/plans/plan-YYYY-MM-DD-[feature].md`
- All implementation files
- QA validation summary

**Best For**:
- End-to-end automation
- Confident feature development
- Quick prototyping
- Learning complete workflow

**Not Recommended When**:
- You need to iterate on research
- Implementation requires user decisions
- You want more control over each phase

---

## Workflow Patterns

### Pattern 1: New Plugin Development

**Recommended Approach**:

```bash
# Step 1: Research similar plugins
/research "How do pre-commit validation plugins work?"

# Step 2: Plan the implementation
/plan "Add mix_audit dependency security scanning plugin"

# Step 3: Implement the plan
/implement mix-audit-plugin

# Step 4: Validate
/qa test mix_audit
/qa validate mix_audit

# Step 5: Final QA before commit
/qa
```

**Or use oneshot**:
```bash
/oneshot "Add mix_audit dependency security scanning plugin"
```

### Pattern 2: Hook Modification

**Recommended Approach**:

```bash
# Step 1: Research current implementation
/research "How does the core plugin auto-format hook work?"

# Step 2: Plan modifications
/plan "Add custom formatter configuration support to core plugin"

# Step 3: Implement changes
/implement custom-format-options

# Step 4: Validate changes
/qa test core
/qa review
```

### Pattern 3: Marketplace Maintenance

**Recommended Approach**:

```bash
# Regular health check
/qa

# Validate all plugins
/qa test

# Check specific plugin
/qa validate core
```

### Pattern 4: Documentation & Learning

**Recommended Approach**:

```bash
# Explore marketplace architecture
/research "How is the plugin marketplace structured?"

# Understand hook patterns
/research "What are the different hook JSON output patterns?"

# Learn test patterns
/research "How are hook tests implemented?"
```

### Pattern 5: Quality Assurance Workflow

**Before Committing**:

```bash
# 1. Run comprehensive QA
/qa

# 2. Review the report
cat .thoughts/YYYY-MM-DD-qa-report.md

# 3. Address any issues

# 4. Re-run QA
/qa

# 5. Commit when ✅ READY TO PUSH
git add -A
git commit -m "Your commit message"

# 6. Final check
/qa review

# 7. Push
git push
```

---

## Best Practices

### Research Phase

**Do**:
- ✅ Research before planning or implementing
- ✅ Focus on similar implementations
- ✅ Document findings with file:line references
- ✅ Look for patterns across multiple plugins
- ✅ Save research for future reference

**Don't**:
- ❌ Skip research for complex features
- ❌ Research without a specific question
- ❌ Ignore existing patterns
- ❌ Forget to document findings

### Planning Phase

**Do**:
- ✅ Create detailed, actionable plans
- ✅ Specify all files to create/modify
- ✅ Include testing strategy
- ✅ Follow existing marketplace patterns
- ✅ Plan for comprehensive validation

**Don't**:
- ❌ Create vague plans
- ❌ Skip testing considerations
- ❌ Plan without researching first
- ❌ Ignore validation requirements

### Implementation Phase

**Do**:
- ✅ Follow the plan strictly
- ✅ Validate JSON and scripts as you go
- ✅ Use proper exit codes and JSON patterns
- ✅ Write comprehensive tests
- ✅ Update documentation
- ✅ Mark todos completed immediately

**Don't**:
- ❌ Deviate from plan without documenting
- ❌ Skip validation steps
- ❌ Forget to update marketplace.json
- ❌ Leave incomplete documentation
- ❌ Skip testing

### QA Phase

**Do**:
- ✅ Run QA before every push
- ✅ Address all critical issues
- ✅ Fix warnings when possible
- ✅ Test in Claude Code manually
- ✅ Validate documentation

**Don't**:
- ❌ Push without running /qa
- ❌ Ignore critical issues
- ❌ Skip manual testing
- ❌ Leave outdated documentation

### General Best Practices

**Version Management**:
- **Plugin version**: Bump when functionality changes
- **Marketplace version**: Bump only when catalog structure changes
- Follow semantic versioning (major.minor.patch)

**JSON Structure**:
- Always validate with `jq . file.json`
- Follow existing schema patterns
- Include all required fields

**Hook Scripts**:
- Use proper shebang: `#!/bin/bash`
- Set error handling: `set -euo pipefail`
- Generate correct JSON output
- Use proper exit codes (0 for success, including blocking with JSON)
- Extract parameters with jq

**Testing**:
- Test all scenarios: file types, commands, blocking
- Verify exit codes and JSON output
- Use descriptive test names
- Follow test-hook.sh patterns

**Documentation**:
- Keep README.md updated
- Document all hooks and behavior
- Include usage examples
- Maintain consistency

---

## Examples

### Example 1: Creating a New Security Plugin

**Goal**: Add sobelow security analysis plugin

**Steps**:

```bash
# 1. Research security scanning patterns
/research "How do security analysis plugins like credo work?"

# Read research: docs/research/research-2025-10-26-security-patterns.md

# 2. Plan the implementation
/plan "Add sobelow security analysis plugin with pre-commit validation"

# Review plan: docs/plans/plan-2025-10-26-sobelow-plugin.md

# 3. Implement the plan
/implement sobelow-plugin

# 4. Test the plugin
/qa test sobelow

# 5. Validate structure
/qa validate sobelow

# 6. Full QA
/qa

# 7. Commit
git add -A
git commit -m "Add sobelow security analysis plugin

- PostToolUse hook for security suggestions
- PreToolUse blocking hook for pre-commit validation
- Comprehensive test suite
- Complete documentation

🤖 Generated with Claude Code
Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Or use oneshot**:

```bash
/oneshot "Add sobelow security analysis plugin with pre-commit validation"

# Review generated artifacts
cat docs/research/research-2025-10-26-sobelow-plugin.md
cat docs/plans/plan-2025-10-26-sobelow-plugin.md

# Test manually in Claude Code
/plugin marketplace reload
/plugin install sobelow@elixir

# Commit
git add -A
git commit -m "Add sobelow plugin (generated via /oneshot)"
```

### Example 2: Modifying Existing Hook

**Goal**: Add timeout support to dialyzer plugin

**Steps**:

```bash
# 1. Research current implementation
/research "How does the dialyzer plugin implement pre-commit validation?"

# 2. Plan the modification
/plan "Add configurable timeout support to dialyzer pre-commit hook"

# 3. Implement changes
/implement dialyzer-timeout-support

# 4. Test changes
/qa test dialyzer

# 5. Review changes
/qa review

# 6. Full QA
/qa
```

### Example 3: Marketplace Maintenance

**Goal**: Ensure marketplace health

**Steps**:

```bash
# 1. Run comprehensive QA
/qa

# 2. Review consolidated report
cat .thoughts/2025-10-26-qa-report.md

# 3. If issues found, investigate
/research "What causes hook validation failures?"

# 4. Plan fixes if needed
/plan "Fix identified issues in hook implementations"

# 5. Implement fixes
/implement hook-fixes

# 6. Re-run QA
/qa

# 7. Commit when clean
git add -A
git commit -m "Marketplace maintenance and quality improvements"
```

### Example 4: Learning the Codebase

**Goal**: Understand marketplace architecture

**Steps**:

```bash
# Explore marketplace structure
/research "How is the plugin marketplace structured?"

# Understand hook patterns
/research "What are the different hook JSON output patterns?"

# Learn test infrastructure
/research "How is the test framework organized?"

# Understand blocking hooks
/research "How do blocking hooks work with permissionDecision?"

# Review all research
ls -la docs/research/
```

---

## Troubleshooting

### Research Phase Issues

**Problem**: Research returns too broad results
**Solution**: Be more specific in your query
```bash
# Too broad
/research "hooks"

# Better
/research "How do PostToolUse hooks handle file filtering?"
```

**Problem**: Can't find relevant patterns
**Solution**: Search for similar functionality
```bash
/research "Find all plugins with pre-commit validation"
```

### Planning Phase Issues

**Problem**: Plan is too vague
**Solution**: Research more thoroughly first
```bash
/research "How do existing plugins implement similar features?"
# Then create plan with concrete examples
```

**Problem**: Unsure about architecture decisions
**Solution**: Ask for clarification before planning
```bash
# Use AskUserQuestion in /plan to get decisions
```

### Implementation Phase Issues

**Problem**: JSON validation fails
**Solution**: Use jq to identify syntax errors
```bash
jq . .claude-plugin/marketplace.json
# Fix syntax errors and re-run
```

**Problem**: Tests failing
**Solution**: Review test output and fix issues
```bash
./test/plugins/[name]/test-[name]-hooks.sh
# Read error messages carefully
# Fix implementation
# Re-run tests
```

**Problem**: Script not executable
**Solution**: Make scripts executable
```bash
chmod +x plugins/[name]/scripts/*.sh
```

### QA Phase Issues

**Problem**: Critical issues blocking push
**Solution**: Fix all ❌ issues before pushing
```bash
# Review detailed report
cat .thoughts/YYYY-MM-DD-qa-report.md

# Fix critical issues
# Re-run QA
/qa
```

**Problem**: Documentation outdated
**Solution**: Update all relevant documentation
```bash
# Update plugin README
# Update marketplace README
# Update CLAUDE.md if needed
# Re-run /qa review
```

**Problem**: Version mismatch
**Solution**: Follow versioning protocol
```bash
# Plugin changed: Bump plugin version in plugin.json
# Marketplace structure changed: Bump marketplace.json version
# Not both unless both changed
```

### General Issues

**Problem**: Workflow interrupted
**Solution**: Use standalone commands to continue
```bash
# If /oneshot interrupted during planning
/plan "feature description"
/implement plan-name

# If /implement interrupted
# Check plan status
cat docs/plans/plan-YYYY-MM-DD-[name].md
# Continue from where it stopped
```

**Problem**: Can't find generated files
**Solution**: Check expected locations
```bash
# Research documents
ls docs/research/

# Plan documents
ls docs/plans/

# QA reports
ls .thoughts/

# Test results
ls .thoughts/test-*
```

---

## Directory Structure Reference

```
.
├── .claude/
│   ├── commands/
│   │   ├── research.md       # /research command
│   │   ├── plan.md           # /plan command
│   │   ├── implement.md      # /implement command
│   │   ├── qa.md             # /qa command
│   │   ├── oneshot.md        # /oneshot command
│   │   └── create-plugin.md  # /create-plugin command
│   └── settings.json         # Plugin configuration
├── .claude-plugin/
│   └── marketplace.json      # Marketplace metadata
├── plugins/
│   └── [plugin-name]/
│       ├── .claude-plugin/
│       │   └── plugin.json   # Plugin metadata
│       ├── hooks/
│       │   └── hooks.json    # Hook definitions
│       ├── scripts/
│       │   └── *.sh          # Hook scripts
│       └── README.md         # Plugin documentation
├── test/
│   └── plugins/
│       └── [plugin-name]/
│           └── test-[name]-hooks.sh  # Test suite
├── docs/
│   ├── research/             # Research documents (generated by /research)
│   ├── plans/                # Plan documents (generated by /plan)
│   └── WORKFLOWS.md          # This file
├── .thoughts/                # QA reports, test results (generated by /qa)
├── CLAUDE.md                 # Project instructions for Claude
└── README.md                 # Marketplace documentation
```

---

## Workflow Command Reference

| Command | Purpose | Output Location | Time Estimate |
|---------|---------|-----------------|---------------|
| `/research [query]` | Explore and document patterns | `docs/research/research-*.md` | 5-10 min |
| `/plan [feature]` | Create implementation plan | `docs/plans/plan-*.md` | 5 min |
| `/implement [plan]` | Execute implementation | Files + plan update | 10-15 min |
| `/qa` | Full quality validation | `.thoughts/*-qa-report.md` | 5-10 min |
| `/qa review` | Pre-push code review | `.thoughts/*-marketplace-review.md` | 3-5 min |
| `/qa test [plugin]` | Run plugin tests | `.thoughts/test-*.md` | 2-5 min |
| `/qa validate <plugin>` | Validate plugin structure | Inline report | 2-3 min |
| `/oneshot [feature]` | Complete workflow | All of the above | 25-35 min |

---

## Version History

- **1.0.0** (2025-10-26): Initial workflow documentation
  - Research workflow
  - Planning workflow
  - Implementation workflow
  - QA workflow
  - Oneshot workflow
  - Best practices guide
  - Examples and troubleshooting

---

## Additional Resources

- **Project Instructions**: `CLAUDE.md`
- **Marketplace README**: `README.md`
- **Test Framework**: `test/README.md`
- **Plugin Examples**: `plugins/*/README.md`

---

## Getting Help

If you encounter issues with workflows:

1. Check this documentation first
2. Review generated reports in `docs/` and `.thoughts/`
3. Research similar implementations: `/research [topic]`
4. Consult `CLAUDE.md` for project-specific guidance
5. Review plugin READMEs for examples

---

**Happy Plugin Development!** 🚀
