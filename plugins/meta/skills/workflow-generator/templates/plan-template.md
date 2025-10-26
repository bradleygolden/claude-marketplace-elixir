---
description: Create detailed implementation plan for Elixir feature or task
argument-hint: [brief-description]
allowed-tools: Read, Grep, Glob, Task, Bash, TodoWrite, Write, AskUserQuestion
---

# Plan

Generate a detailed, phased implementation plan for Elixir projects.

## Purpose

Create executable implementation plans with clear phases, success criteria, and verification steps for Elixir development.

## Steps to Execute:

### Step 1: Context Gathering

**Read referenced files completely:**
- If user references files, code, or tickets, read them FULLY first
- Use Read tool WITHOUT limit/offset parameters
- Gather complete context before any planning

**Spawn parallel research agents:**

Use Task tool to spawn agents that will inform your plan:

1. **codebase-locator** (subagent_type="general-purpose"):
   - Find relevant Elixir modules, contexts, schemas
   - Locate similar implementations for reference
   - Identify files that will need modification

2. **codebase-analyzer** (subagent_type="general-purpose"):
   - Analyze existing patterns and conventions
   - Understand current architecture and design
   - Trace how similar features are implemented

3. **Skill** (core:hex-docs-search):
   - Research relevant Hex packages if needed
   - Understand framework patterns (Phoenix, Ecto, etc.)
   - Find official documentation for libraries

**Wait for all agents** before proceeding.

**Present your informed understanding:**
- Summarize what you learned with file:line references
- Show the current implementation state
- Identify what needs to change

**Ask ONLY questions that code cannot answer:**
- Design decisions and trade-offs
- User preferences between valid approaches
- Clarifications on requirements

### Step 2: Research & Discovery

If user provides corrections or additional context:
- Verify through additional research
- Spawn new sub-agents if needed
- Update your understanding

**Present design options:**
- Show 2-3 valid approaches with pros/cons
- Include code examples for each approach
- Reference similar patterns in the codebase
- Explain trade-offs specific to Elixir/Phoenix

**Get user approval** on approach before writing detailed plan.

### Step 3: Plan Structure Proposal

**Propose phased implementation outline** based on {{PLANNING_STYLE}}:

{{#if PLANNING_STYLE equals "Detailed phases"}}
**Phased Structure:**
1. Phase 1: [Name] - [Brief description]
2. Phase 2: [Name] - [Brief description]
3. Phase 3: [Name] - [Brief description]

Each phase will include:
- Specific module/file changes
- Code examples showing changes
- Verification steps
{{/if}}

{{#if PLANNING_STYLE equals "Task checklist"}}
**Task Checklist Structure:**
- [ ] Task 1: [Description]
- [ ] Task 2: [Description]
- [ ] Task 3: [Description]

Each task will include:
- Files to modify
- Expected outcome
- How to verify
{{/if}}

{{#if PLANNING_STYLE equals "Milestone-based"}}
**Milestone Structure:**
- Milestone 1: [Deliverable]
- Milestone 2: [Deliverable]
- Milestone 3: [Deliverable]

Each milestone will include:
- Tasks required
- Acceptance criteria
- Verification approach
{{/if}}

**Get user approval** before writing detailed plan.

### Step 4: Write Detailed Plan

**Gather metadata:**
```bash
date +"%Y-%m-%d" && git log -1 --format="%H" && git branch --show-current && git config user.name
```

**Create plan file:**
- Location: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-description.md`
- Format: `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-brief-kebab-case-description.md`
- Example: `{{DOCS_LOCATION}}/plans/2025-01-23-add-user-authentication.md`

**Plan Template:**

```markdown
---
date: [ISO timestamp]
author: [Git user name]
commit: [Current commit hash]
branch: [Current branch name]
repository: [Repository name]
title: "[Feature/Task Description]"
status: planned
tags: [plan, elixir, {{PROJECT_TYPE_TAGS}}]
---

# Plan: [Feature/Task Description]

**Date**: [Current date]
**Author**: [Git user name]
**Branch**: [Current branch]
**Project Type**: {{PROJECT_TYPE}}

## Overview

[2-3 sentences describing what this plan accomplishes and why]

## Current State

[Describe the current implementation with file:line references]

**Existing Modules:**
- `lib/my_app/context.ex` - [What it currently does]
- `lib/my_app_web/controllers/controller.ex` - [What it currently does]

**Current Behavior:**
[Describe how the system currently works in this area]

## Desired End State

[Describe the target implementation]

**New/Modified Modules:**
- `lib/my_app/new_context.ex` - [What it will do]
- `lib/my_app/schemas/new_schema.ex` - [What it will contain]

**Target Behavior:**
[Describe how the system should work after implementation]

{{#if PLANNING_STYLE equals "Detailed phases"}}
## Implementation Phases

### Phase 1: [Phase Name]

**Goal**: [What this phase accomplishes]

**Changes Required:**

1. **Create/Modify** `lib/my_app/schema.ex`
   ```elixir
   defmodule MyApp.Schema do
     use Ecto.Schema
     import Ecto.Changeset

     schema "table" do
       field :name, :string
       # Add fields
       timestamps()
     end

     def changeset(struct, params) do
       struct
       |> cast(params, [:name])
       |> validate_required([:name])
     end
   end
   ```

2. **Create/Modify** `lib/my_app/context.ex`
   ```elixir
   defmodule MyApp.Context do
     alias MyApp.{Repo, Schema}

     def create_thing(attrs) do
       %Schema{}
       |> Schema.changeset(attrs)
       |> Repo.insert()
     end
   end
   ```

**Verification:**
- [ ] `mix compile --warnings-as-errors` succeeds
- [ ] {{TEST_COMMAND}} passes
- [ ] Schema migration runs cleanly
{{/if}}

{{#if PLANNING_STYLE equals "Task checklist"}}
## Implementation Tasks

- [ ] **Task 1**: Create Ecto schema for [entity]
  - File: `lib/my_app/schemas/entity.ex`
  - Include fields: [list]
  - Add validations: [list]
  - Verify: Schema tests pass

- [ ] **Task 2**: Add context functions
  - File: `lib/my_app/contexts/context.ex`
  - Functions: create/1, update/2, delete/1, list/0
  - Verify: Context tests pass

- [ ] **Task 3**: Create controller/LiveView
  - File: `lib/my_app_web/controllers/entity_controller.ex`
  - Actions: index, show, new, create, edit, update, delete
  - Verify: Controller tests pass
{{/if}}

{{#if PLANNING_STYLE equals "Milestone-based"}}
## Implementation Milestones

### Milestone 1: Database Layer Complete

**Deliverables:**
- Ecto schema with validations
- Migration file
- Basic CRUD context functions

**Tasks:**
- Create schema module
- Write migration
- Implement context
- Add tests

**Acceptance Criteria:**
- All database operations work
- Tests cover happy and error paths
- Migration runs without errors

### Milestone 2: Web Layer Complete

**Deliverables:**
- Controller or LiveView
- Templates/HEEx
- Routes configured

**Tasks:**
- Create controller/LiveView
- Add templates
- Update router
- Add integration tests

**Acceptance Criteria:**
- All CRUD operations accessible via web
- UI renders correctly
- Integration tests pass
{{/if}}

## Success Criteria

### Automated Verification

Run these commands to verify implementation:

- [ ] **Compilation**: `mix compile --warnings-as-errors` succeeds
- [ ] **Tests**: {{TEST_COMMAND}} passes
{{QUALITY_TOOLS_CHECKS}}

### Manual Verification

Human verification required:

- [ ] Feature works as expected in browser/IEx
- [ ] Edge cases handled appropriately
- [ ] Error messages are clear and helpful
- [ ] Documentation updated (@moduledoc, @doc)
- [ ] No console errors or warnings
- [ ] Performance is acceptable

## Dependencies

[List any Hex packages that need to be added to mix.exs]

## Configuration Changes

[List any config changes needed in config/]

## Migration Strategy

[If database changes, describe migration approach]

## Rollback Plan

[How to undo these changes if needed]

## Notes

[Any additional context, decisions, or considerations]
```

### Step 5: Present Plan

**Show user the created plan:**
- Location of plan file
- Brief summary of phases/tasks
- Success criteria overview

**Confirm readiness:**
- Ask if plan looks good or needs adjustments
- Offer to clarify any phase/task
- Ready to proceed to implementation

## Important Guidelines

### Complete Alignment Required

**No open questions in final plan:**
- All technical decisions resolved
- All design choices made
- All ambiguities clarified
- Ready for immediate execution

### Success Criteria Format

**Separate automated from manual:**

**Automated** = Can run via command:
- `{{TEST_COMMAND}}`
- `mix compile --warnings-as-errors`
- `mix format --check-formatted`
{{QUALITY_TOOLS_EXAMPLES}}

**Manual** = Requires human verification:
- UI functionality
- UX quality
- Edge case handling
- Documentation quality

### Code Examples Required

Every phase/task with code changes MUST include:
- Specific file paths
- Actual Elixir code examples
- Not pseudo-code or placeholders
- Show imports, use statements, module attributes

### Elixir-Specific Considerations

**For Phoenix projects:**
- Context boundaries and public APIs
- Controller vs LiveView choice
- Route placement and naming
- Template organization

**For Ecto changes:**
- Schema design and relationships
- Changeset validations
- Migration strategy (reversible)
- Repo operations (transaction needs)

**For Process-based features:**
- Supervision tree placement
- GenServer/Agent design
- Message passing patterns
- Process naming and registration

## Non-Negotiable Standards

1. **Research first**: Always gather context before planning
2. **No placeholders**: Every code example must be real Elixir code
3. **File references**: Always include specific file paths
4. **Success criteria**: Always separate automated vs manual
5. **User approval**: Get approval on approach before detailed plan
6. **Complete plan**: No open questions when finished

## Example Scenario

**User**: "Add user authentication to the Phoenix app"

**Process**:
1. Research existing auth patterns in codebase
2. Present options: Guardian vs Pow vs custom
3. User chooses Guardian
4. Propose 5 phases: Schema, Context, Plugs, Controllers, Tests
5. User approves
6. Write detailed plan with Guardian-specific code examples
7. Include Guardian dependency in plan
8. Define success criteria (auth tests pass, login works)
