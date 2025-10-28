---
description: Gather context through interactive questioning to guide workflow execution
argument-hint: [workflow-phase]
allowed-tools: Read, Glob, Bash, TodoWrite, Write, AskUserQuestion
---

# Interview

You are tasked with gathering context through interactive questioning to guide workflow execution. This command intelligently determines what questions to ask based on the current workflow state.

## Steps to Execute:

### 1. Parse Arguments and Detect Context

**Check for explicit workflow phase argument:**
- If user provides argument (e.g., `/interview research`, `/interview plan`), use that as target phase
- If no argument, auto-detect based on existing documents

**Auto-detect workflow phase:**

Use Glob to check for existing documents:
```bash
# Check for existing workflow documents
ls {{DOCS_LOCATION}}/research/research-*.md 2>/dev/null
ls {{DOCS_LOCATION}}/plans/plan-*.md 2>/dev/null
ls {{DOCS_LOCATION}}/interview/interview-*.md 2>/dev/null
```

**Detection logic:**
- No research docs exist → Target: `pre-research`
- Research docs exist, no plan docs → Target: `pre-plan`
- Both research and plan exist → Target: `pre-implement`
- Interview doc already exists → Target: `follow-up` (refine context)

**Create TodoWrite tracking:**
```
1. [in_progress] Detect workflow context and target phase
2. [pending] Analyze context and formulate relevant questions
3. [pending] Ask context gathering questions
4. [pending] Process and validate answers
5. [pending] Generate derived context and recommendations
6. [pending] Write interview document
7. [pending] Present interview summary
```

Mark first todo as completed, second as in_progress.

---

### 2. Analyze Context and Formulate Questions

**Analyze the current situation:**

1. **Read relevant context:**
   - If pre-research: Read the user's research query to understand what they're asking about
   - If pre-plan: Read research documents (if they exist) and the user's feature description
   - If pre-implement: Read plan documents to understand what's being implemented

2. **Identify what information is needed:**
   - What decisions cannot be made by code analysis alone?
   - What preferences or trade-offs require user input?
   - What constraints or requirements are unclear?
   - What aspects of the task are ambiguous?

3. **Formulate contextual questions (as many as needed):**
   - Questions should be specific to the actual task at hand
   - Focus on decisions that will meaningfully impact the workflow
   - Avoid generic questions that don't apply to this specific situation
   - Ask as many questions as necessary to gather sufficient context (typically 2-6)
   - Each question should have 2-4 relevant options
   - Note: AskUserQuestion tool supports 1-4 questions per call, so make multiple calls if needed

**Question Formulation Guidelines:**

**For Pre-Research Phase:**
Analyze the research query and determine:
- Is the scope clear or ambiguous?
- What depth of investigation is appropriate?
- Are there specific aspects to focus on or avoid?
- What format would be most useful for the results?

Example questions (adapt to actual query):
- Scope: How deep should the research go?
- Focus: What specific aspects matter most?
- Constraints: Any time/scope limitations?

**For Pre-Plan Phase:**
Analyze research findings (if available) and feature description:
- Are there multiple valid architectural approaches?
- What are the key trade-offs that need user input?
- What priorities should guide the design?
- Are there specific patterns or conventions to follow?

Example questions (adapt to actual feature):
- Architecture: What design approach is preferred?
- Priorities: What matters most (performance, maintainability, simplicity)?
- Testing: What level of test coverage is needed?

**For Pre-Implement Phase:**
Analyze the plan and identify implementation preferences:
- Are there style or convention questions?
- What's the preferred implementation sequence?
- What validation criteria are most important?
- Are there any implementation constraints?

Example questions (adapt to actual plan):
- Style: Follow existing patterns or introduce improvements?
- Approach: Iterative or complete-then-test?
- Validation: What quality checks are critical?

**For Follow-Up Phase:**
Read existing interview document and identify:
- What aspects need refinement or clarification?
- What new information has emerged?
- What decisions need to be revisited?

### 3. Ask Context Gathering Questions

Use AskUserQuestion to ask the dynamically formulated questions.

**Important:**
- Ask as many questions as needed to gather sufficient context
- AskUserQuestion supports 1-4 questions per call - make multiple calls if you have more questions
- Each question must have clear header (≤12 chars), question text, and 2-4 options
- Options should have concise labels (1-5 words) and helpful descriptions
- Use multiSelect: true when options are not mutually exclusive
- Use multiSelect: false for mutually exclusive choices
- Always provide an "opt-out" option if appropriate (e.g., "Not sure", "Show me options", "No constraints")

**If you have more than 4 questions:**
1. Ask first batch (1-4 questions) with AskUserQuestion
2. Process those answers
3. Ask next batch (1-4 questions) with another AskUserQuestion call
4. Continue until all necessary questions are asked

Mark second todo as completed, third as in_progress.

---

### 4. Process and Validate Answers

**Capture answers:**
- Store each answer with its question context
- Note which questions used multi-select (answers are arrays)
- Validate that critical questions were answered

**Derive context from answers:**

**For Pre-Research:**
- Translate scope selection into research depth guidance
- Map focus areas to specific components/patterns to investigate
- Convert constraints into research boundaries
- Generate specific research directives

**For Pre-Plan:**
- Translate architecture preference into design approach
- Map priorities to plan structure and detail level
- Convert testing strategy into test plan requirements
- Generate planning directives

**For Pre-Implement:**
- Translate code style into implementation guidelines
- Map approach to implementation sequence
- Convert validation priorities into quality gates
- Generate implementation directives

**Generate recommendations:**
- Specific actions for the next workflow step
- File/directory focus areas
- Patterns to follow or avoid
- Quality criteria to meet

Mark third todo as completed, fourth as in_progress.

---

### 5. Generate Derived Context and Recommendations

Based on processed answers, create actionable guidance for subsequent workflow steps.

**Context structure:**

```markdown
## Workflow Directives

### For [Target Phase]
[Specific instructions based on answers]

### Focus Areas
[What to prioritize]

### Constraints
[What to avoid or limitations to respect]

### Quality Criteria
[Success metrics for this phase]
```

**Example derivations:**

**If user selected "Deep technical dive" + "Data flow" + "Integration points":**
```
Research Directive: Use analyzer agents to trace complete execution flows.
Focus on how data moves between components and integration boundaries.
Document each step with file:line references and data transformations.
```

**If user selected "Minimal viable" + "Maintainability" + "Follow existing":**
```
Plan Directive: Design should match existing patterns in the codebase.
Prioritize code clarity and simplicity over optimization.
Include refactoring opportunities only if they improve maintainability.
```

Mark fourth todo as completed, fifth as in_progress.

---

### 6. Write Interview Document

**Gather metadata:**
```bash
date -u +"%Y-%m-%d %H:%M:%S %Z"
git log -1 --format="%H"
git branch --show-current
git config user.name
```

**Determine filename:**
- Format: `{{DOCS_LOCATION}}/interview/interview-YYYY-MM-DD-[phase]-[brief-topic].md`
- Examples:
  - `{{DOCS_LOCATION}}/interview/interview-2025-10-28-pre-research-authentication.md`
  - `{{DOCS_LOCATION}}/interview/interview-2025-10-28-pre-plan-monitoring-plugin.md`
  - `{{DOCS_LOCATION}}/interview/interview-2025-10-28-pre-implement-api-refactor.md`

**Create {{DOCS_LOCATION}}/interview/ directory if needed:**
```bash
mkdir -p {{DOCS_LOCATION}}/interview
```

**Document structure:**

```markdown
---
date: [ISO timestamp]
interviewer: [Git user name]
commit: [Current commit hash]
branch: [Current branch name]
repository: [Repository name from git remote]
workflow_phase: "[pre-research|pre-plan|pre-implement|follow-up]"
target_workflow: "[research|plan|implement]"
tags: [interview, context-gathering, workflow-phase]
status: complete
---

# Interview: Context for [Target Workflow]

**Date**: [timestamp]
**Interviewer**: [user]
**Git Commit**: [hash]
**Branch**: [branch]
**Workflow Phase**: [phase]
**Target Workflow**: [target]

## Interview Summary

[High-level summary of gathered context - 2-3 sentences about what was learned]

## Questions and Answers

### Question 1: [Question text]
**Header**: [header]
**Answer**: [User's selection(s)]

**Context**: [What this means for the workflow - how this answer guides execution]

### Question 2: [Question text]
**Header**: [header]
**Answer**: [User's selection(s)]

**Context**: [What this means for the workflow]

### Question 3: [Question text]
**Header**: [header]
**Answer**: [User's selection(s)]

**Context**: [What this means for the workflow]

[Repeat for all questions asked]

## Derived Context

[Processed answers transformed into actionable guidance]

### Workflow Directives

[Specific instructions for the target workflow step based on answers]

### Focus Areas

[What to prioritize, specific components/patterns to investigate or implement]

### Constraints and Boundaries

[Limitations, areas to avoid, time constraints, etc.]

### Quality Criteria

[Success metrics for the target workflow phase]

## Recommendations for [Target Workflow]

[Numbered list of specific, actionable recommendations]

1. [Specific directive based on answers]
2. [Specific directive based on answers]
3. [Specific directive based on answers]

## Next Steps

**To use this context:**

[IF pre-research:]
Run: `/research [your-topic]`
The research command will automatically detect and use this interview context.

[IF pre-plan:]
Run: `/plan [your-feature]`
The plan command will automatically detect and use this interview context.

[IF pre-implement:]
Run: `/implement [plan-name]`
The implement command can reference this context for implementation decisions.

[IF follow-up:]
This follow-up interview updates the context for ongoing work.
Subsequent workflow commands will use the refined context.
```

**Write document:**
- Use Write tool to create the interview document
- Include all gathered information
- Ensure all sections are complete

Mark fifth todo as completed, sixth as in_progress.

---

### 7. Present Interview Summary

Present concise summary to user:

```markdown
# Interview Complete

**Workflow Phase**: [phase]
**Target Workflow**: [target]

## Context Gathered

**Scope**: [summary of scope/approach selected]
**Priorities**: [key priorities identified]
**Constraints**: [any constraints or special requirements]

## Key Directives

[3-5 most important directives for next workflow step]

## Interview Document

**Location**: `{{DOCS_LOCATION}}/interview/interview-YYYY-MM-DD-[phase]-[topic].md`

This context will be automatically detected and used by subsequent workflow commands.

## Next Steps

[IF pre-research:]
You can now run:
```bash
/research [your-research-topic]
```
The research command will use this interview context to focus its investigation.

[IF pre-plan:]
You can now run:
```bash
/plan [your-feature-description]
```
The plan command will use this interview context to guide design decisions.

[IF pre-implement:]
You can now run:
```bash
/implement [your-plan-name]
```
The implement command can reference this context for implementation preferences.

[IF follow-up:]
The interview context has been updated. Continue with your workflow - commands will use the refined context.
```

Mark sixth todo as completed, all todos complete.

---

## Important Notes

### Dynamic Question Generation

The interview command does NOT use hardcoded questions. Instead:
- Analyze the specific task/query/feature being worked on
- Read relevant context (research docs, plan docs, user's query)
- Identify what decisions actually need user input for THIS specific situation
- Formulate 2-4 contextual questions that directly address those decisions
- Generate appropriate options based on the actual context

This ensures questions are always relevant and meaningful, not generic.

### Context Detection Logic

The command intelligently determines what questions to ask based on:
1. **Explicit argument**: User can specify phase (`/interview research`, `/interview plan`)
2. **Existing documents**: Auto-detect based on what workflow docs exist
3. **Interview history**: Check for existing interview docs to avoid redundant questions

### Answer Processing

- Single-select answers: String value
- Multi-select answers: Array of string values
- Always provide context interpretation for each answer
- Generate specific, actionable directives from answers

### Document Location

Interview documents are stored in `{{DOCS_LOCATION}}/interview/` for:
- Persistence across workflow steps
- Reference by subsequent commands
- Tracking of context evolution

### Integration with Workflows

Interview documents are referenced by:
- `/research` - Checks for interview doc at start, uses context to focus research
- `/plan` - Checks for interview doc at start, uses context for design decisions
- `/implement` - Can reference interview doc for implementation preferences

### Follow-Up Interviews

If an interview document already exists:
- Ask if user wants to refine existing context
- Update existing document with refinements
- Add follow-up section with timestamp

## Example Usage

**User**: `/interview` (before researching "How does the plugin hook system work?")

**Process**:
1. Detect no research docs exist → Target: pre-research
2. Read user's research query: "How does the plugin hook system work?"
3. Analyze: This is about understanding architecture and execution flow
4. Formulate contextual questions:
   - Q1: "How deep should we investigate the hook system?" (Single-select: High-level flow, Detailed execution trace, Pattern comparison, Implementation examples)
   - Q2: "Which aspects of hooks are most important?" (Multi-select: Hook registration, Event triggering, Script execution, Error handling)
   - Q3: "Any specific constraints?" (Multi-select: Time-sensitive, Focus on specific hooks, Include tests, No constraints)
5. User answers questions
6. Process answers into research directives specific to the hook system
7. Generate interview document
8. Present summary with next steps to run `/research`

**User**: `/interview plan` (after researching, before planning "Add monitoring plugin")

**Process**:
1. Explicit phase provided → Target: pre-plan
2. Read research document about similar plugins (credo, dialyzer patterns)
3. Analyze: Multiple valid approaches for monitoring (health checks, metrics, alerts)
4. Formulate contextual questions:
   - Q1: "What type of monitoring?" (Single-select: Health checks, Metrics collection, Alert integration, All of the above)
   - Q2: "When should monitoring run?" (Single-select: PostToolUse, PreToolUse, Both, On-demand)
   - Q3: "What matters most for this plugin?" (Multi-select: Performance overhead, Detailed output, Integration with tools, Ease of configuration)
5. User answers questions
6. Process into planning directives specific to monitoring plugin design
7. Generate interview document
8. Present summary with next steps to run `/plan`

Note how questions are specific to the actual task, not generic templates.
