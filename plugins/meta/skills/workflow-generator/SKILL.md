---
name: workflow-generator
description: Generate project-specific workflow commands (research, plan, implement, qa) by asking questions about the project and creating customized commands
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, TodoWrite
---

# Workflow Generator Skill

This skill generates a complete set of project-specific workflow commands by asking questions about your project and creating customized `/research`, `/plan`, `/implement`, and `/qa` commands.

## Purpose

Create a standardized workflow system adapted to any project's:
- Tech stack and language
- Build/test commands
- Documentation structure
- Quality gates and validation criteria
- Planning methodology

## Template System

### Template Path Resolution

Templates are stored in `plugins/meta/skills/workflow-generator/templates/`. When this skill uses the Read tool:
- **During marketplace development**: Paths are relative to repository root
- **When plugin is installed**: Claude Code resolves paths relative to plugin installation location
- Template paths in this skill use the format: `plugins/meta/skills/workflow-generator/templates/<template-name>.md`

### Template Syntax

Templates use two types of variable substitution:

**1. Simple Variable Substitution**
Replace `{{VARIABLE}}` with actual values:
```
{{PROJECT_TYPE}} → "Phoenix Application"
{{DOCS_LOCATION}} → ".thoughts"
{{TEST_COMMAND}} → "mix test"
```

**2. Handlebars Conditionals** (in some templates)
Templates may use Handlebars syntax for conditional content:
```
{{#if PLANNING_STYLE equals "Detailed phases"}}
  Phase-based content
{{/if}}

{{#if PLANNING_STYLE equals "Task checklist"}}
  Checklist-based content
{{/if}}
```

**How to handle Handlebars syntax:**
- Handlebars conditionals are preserved in generated commands (not substituted)
- The generated command will contain the conditional logic
- Claude will evaluate conditionals when the command is executed
- This allows generated commands to adapt behavior based on context

## Execution Flow

When invoked, this skill will:

1. **Discover Project Context**
2. **Ask Customization Questions**
3. **Generate Workflow Commands**
4. **Create Supporting Documentation**
5. **Provide Usage Instructions**

---

## Step 1: Discover Project Context

### 1.1 Detect Project Type

Analyze the current directory to understand the project:

```bash
# Check for common project markers
ls package.json 2>/dev/null && echo "nodejs"
ls mix.exs 2>/dev/null && echo "elixir"
ls Cargo.toml 2>/dev/null && echo "rust"
ls go.mod 2>/dev/null && echo "go"
ls setup.py pyproject.toml 2>/dev/null && echo "python"
ls pom.xml build.gradle 2>/dev/null && echo "java"
```

### 1.2 Check Existing Structure

```bash
# Check for existing .claude directory
ls .claude/commands/*.md 2>/dev/null | wc -l
ls .claude/agents/*.md 2>/dev/null | wc -l
```

### 1.3 Detect Build Tools

Look for common build/test patterns:
- Makefile with test target
- package.json with scripts
- mix.exs with test tasks
- Cargo.toml
- go.mod

---

## Step 2: Ask Customization Questions

Use TodoWrite to track progress:
```
1. [in_progress] Discover project context
2. [pending] Ask customization questions
3. [pending] Generate /research command
4. [pending] Generate /plan command
5. [pending] Generate /implement command
6. [pending] Generate /qa command
7. [pending] Generate /oneshot command
8. [pending] Generate /interview command
9. [pending] Create documentation
10. [pending] Present usage instructions
```

Mark step 1 completed, step 2 in progress.

### Question 1: Elixir Project Type

**Header**: "Project Type"
**Question**: "What type of Elixir project is this?"
**multiSelect**: false
**Options**:
1. Label: "Phoenix Application", Description: "Phoenix web application (full-stack, API, LiveView)"
2. Label: "Library/Package", Description: "Reusable Hex package or library"
3. Label: "CLI/Escript", Description: "Command-line application or escript"
4. Label: "Umbrella Project", Description: "Umbrella project with multiple apps"

### Question 2: Test Strategy

**Header**: "Testing"
**Question**: "How do you run tests?"
**multiSelect**: false
**Options**:
1. Label: "mix test", Description: "Standard Mix test command"
2. Label: "make test", Description: "Using Makefile with test target"
3. Label: "Custom script", Description: "Custom test script or command"

### Question 3: Documentation Location

**Header**: "Docs Location"
**Question**: "Where should workflow documents (research, plans) be saved?"
**multiSelect**: false
**Options**:
1. Label: ".thoughts/", Description: "Hidden .thoughts directory (default pattern)"
2. Label: "docs/", Description: "Standard docs directory"
3. Label: ".claude/thoughts/", Description: "Inside .claude directory"
4. Label: "thoughts/", Description: "Visible thoughts directory"

### Question 4: Quality Tools

**Header**: "Quality Tools"
**Question**: "Which Elixir quality tools do you use?"
**multiSelect**: true
**Options**:
1. Label: "Credo", Description: "Static code analysis with Credo"
2. Label: "Dialyzer", Description: "Type checking with Dialyzer"
3. Label: "Sobelow", Description: "Security scanning for Phoenix apps"
4. Label: "ExDoc", Description: "Documentation validation"
5. Label: "mix_audit", Description: "Dependency security audit"
6. Label: "Format check", Description: "Code formatting validation"

### Question 5: Planning Style

**Header**: "Planning"
**Question**: "How detailed should implementation plans be?"
**multiSelect**: false
**Options**:
1. Label: "Detailed phases", Description: "Break work into numbered phases with specific file changes"
2. Label: "Task checklist", Description: "Simple checklist of tasks to complete"
3. Label: "Milestone-based", Description: "Organize by milestones/deliverables"

### Question 6: WORKFLOWS.md Location

**Header**: "Workflows Doc"
**Question**: "Where should the WORKFLOWS.md documentation file be saved?"
**multiSelect**: false
**Options**:
1. Label: ".claude/WORKFLOWS.md", Description: "Inside .claude directory (recommended)"
2. Label: "WORKFLOWS.md", Description: "Project root directory"
3. Label: "docs/WORKFLOWS.md", Description: "Inside docs directory"
4. Label: "README-WORKFLOWS.md", Description: "Project root with README prefix"

---

## Step 3: Generate /research Command

Mark step 3 as in_progress in TodoWrite.

**Read the template:**
- Use Read tool to read `plugins/meta/skills/workflow-generator/templates/research-template.md`
- This contains the full command structure with placeholders

**Perform variable substitution:**

Replace these variables in the template:
- `{{PROJECT_TYPE}}` → Answer from Question 1 (e.g., "Phoenix Application")
- `{{DOCS_LOCATION}}` → Answer from Question 3 (e.g., ".thoughts")
- `{{PROJECT_TYPE_TAGS}}` → Tags based on project type:
  - Phoenix Application → "phoenix, web, elixir"
  - Library/Package → "library, hex, elixir"
  - CLI/Escript → "cli, escript, elixir"
  - Umbrella Project → "umbrella, multi-app, elixir"
- `{{PROJECT_TYPE_SPECIFIC}}` → Project-specific component types for agent prompts:
  - Phoenix Application → "Phoenix contexts, controllers, LiveViews, and schemas"
  - Library/Package → "public API modules and functions"
  - CLI/Escript → "CLI commands, Mix tasks, and escript entry points"
  - Umbrella Project → "umbrella apps and shared modules"

**Write customized command:**
- Use Write tool to create `.claude/commands/research.md`
- Content is the template with all variables substituted

Mark step 3 completed in TodoWrite.

---

## Step 4: Generate /plan Command

Mark step 4 as in_progress in TodoWrite.

**Read the template:**
- Use Read tool to read `plugins/meta/skills/workflow-generator/templates/plan-template.md`
- This contains the full command structure with placeholders

**Perform variable substitution:**

Replace these variables in the template:
- `{{PLANNING_STYLE}}` → Answer from Question 5 (e.g., "Detailed phases")
- `{{DOCS_LOCATION}}` → Answer from Question 3 (e.g., ".thoughts")
- `{{TEST_COMMAND}}` → Answer from Question 2, map to actual command:
  - "mix test" → "mix test"
  - "make test" → "make test"
  - "Custom script" → Ask user what command to use
- `{{PROJECT_TYPE}}` → Answer from Question 1
- `{{PROJECT_TYPE_TAGS}}` → Same tags as research command
- `{{QUALITY_TOOLS_CHECKS}}` → Expand based on Question 4 answers:
  - If "Credo" selected: Add "- [ ] `mix credo --strict` passes"
  - If "Dialyzer" selected: Add "- [ ] `mix dialyzer` passes"
  - If "Sobelow" selected: Add "- [ ] `mix sobelow --exit Low` passes"
  - If "Format check" selected: Add "- [ ] `mix format --check-formatted` passes"
  - If "ExDoc" selected: Add "- [ ] `mix docs` succeeds (no warnings)"
  - If "mix_audit" selected: Add "- [ ] `mix deps.audit` passes"
- `{{QUALITY_TOOLS_EXAMPLES}}` → Same expansion as checks but as examples

**Write customized command:**
- Use Write tool to create `.claude/commands/plan.md`
- Content is the template with all variables substituted

Mark step 4 completed in TodoWrite.

---

## Step 5: Generate /implement Command

Mark step 5 as in_progress in TodoWrite.

**Read the template:**
- Use Read tool to read `plugins/meta/skills/workflow-generator/templates/implement-template.md`
- This contains the full command structure with placeholders

**Perform variable substitution:**

Replace these variables in the template:
- `{{DOCS_LOCATION}}` → Answer from Question 3
- `{{TEST_COMMAND}}` → Actual test command from Question 2
- `{{VERIFICATION_COMMANDS}}` → Per-phase verification commands:
  ```bash
  # Always include:
  mix compile --warnings-as-errors
  {{TEST_COMMAND}}
  mix format --check-formatted

  # Add if selected in Question 4:
  mix credo --strict  # if Credo
  mix dialyzer  # if Dialyzer
  ```
- `{{FULL_VERIFICATION_SUITE}}` → All quality checks expanded:
  - Always: compile, test, format
  - Conditionally: Credo, Dialyzer, Sobelow, ExDoc, mix_audit (if selected)
- `{{QUALITY_TOOLS_SUMMARY}}` → Summary line for each enabled tool
- `{{OPTIONAL_QUALITY_CHECKS}}` → Per-phase optional checks if tools enabled

**Write customized command:**
- Use Write tool to create `.claude/commands/implement.md`
- Content is the template with all variables substituted

Mark step 5 completed in TodoWrite.

---

## Step 6: Generate /qa Command

Mark step 6 as in_progress in TodoWrite.

**Read the template:**
- Use Read tool to read `plugins/meta/skills/workflow-generator/templates/qa-template.md`
- This contains the full command structure with placeholders

**Perform variable substitution:**

Replace these variables in the template:
- `{{PROJECT_TYPE}}` → Answer from Question 1
- `{{TEST_COMMAND}}` → Actual test command from Question 2
- `{{DOCS_LOCATION}}` → Answer from Question 3
- `{{PROJECT_TYPE_TAGS}}` → Same tags as research command
- `{{QUALITY_TOOL_COMMANDS}}` → Expand quality tool commands based on Question 4:
  ```bash
  # Add for each selected tool:
  mix credo --strict  # if Credo
  mix dialyzer  # if Dialyzer
  mix sobelow --exit Low  # if Sobelow
  mix format --check-formatted  # if Format check
  mix docs  # if ExDoc
  mix deps.audit  # if mix_audit
  ```
- `{{QUALITY_TOOLS_RESULTS_SUMMARY}}` → Summary lines for report template
- `{{QUALITY_TOOLS_DETAILED_RESULTS}}` → Detailed result sections for enabled tools
- `{{SUCCESS_CRITERIA_CHECKLIST}}` → Checklist items for each enabled tool
- `{{PROJECT_TYPE_SPECIFIC_OBSERVATIONS}}` → Phoenix/Ecto/OTP observations based on project type
- `{{QUALITY_TOOL_INTEGRATION_GUIDE}}` → Integration guidance for enabled tools
- `{{QUALITY_TOOLS_SUMMARY_DISPLAY}}` → Display format for enabled tools in final output

**Write customized command:**
- Use Write tool to create `.claude/commands/qa.md`
- Content is the template with all variables substituted

Mark step 6 completed in TodoWrite.

---

## Step 7: Generate /oneshot Command

Mark step 7 as in_progress in TodoWrite.

**Read the template:**
- Use Read tool to read `plugins/meta/skills/workflow-generator/templates/oneshot-template.md`
- This contains the full command structure with placeholders

**Perform variable substitution:**

Replace these variables in the template:
- `{{FEATURE_DESCRIPTION}}` → User's feature description (from $ARGUMENTS)
- `{{DOCS_LOCATION}}` → Answer from Question 3
- `{{TEST_COMMAND}}` → Actual test command from Question 2
- `{{PROJECT_TYPE}}` → Answer from Question 1
- `{{QUALITY_TOOLS}}` → Boolean check if any quality tools selected
- `{{QUALITY_TOOLS_SUMMARY}}` → Comma-separated list of enabled tools
- `{{QUALITY_TOOLS_STATUS}}` → Status summary for each tool
- `{{QUALITY_TOOLS_LIST}}` → List format of enabled tools
- `{{QA_PASSED}}` → Conditional variable for success/failure branching

**Write customized command:**
- Use Write tool to create `.claude/commands/oneshot.md`
- Content is the template with all variables substituted

Mark step 7 completed in TodoWrite.

---

## Step 8: Generate /interview Command

Mark step 8 as in_progress in TodoWrite.

**Read the template:**
- Use Read tool to read `plugins/meta/skills/workflow-generator/templates/interview-template.md`
- This contains the full command structure with placeholders

**Perform variable substitution:**

Replace these variables in the template:
- `{{PROJECT_TYPE}}` → Answer from Question 1 (e.g., "Phoenix Application")
- `{{DOCS_LOCATION}}` → Answer from Question 3 (e.g., ".thoughts")

The interview command is designed to be project-agnostic with dynamic question generation, so it needs minimal customization compared to other commands.

**Write customized command:**
- Use Write tool to create `.claude/commands/interview.md`
- Content is the template with variables substituted

Mark step 8 completed in TodoWrite.

---

## Step 9: Create Documentation

Mark step 9 as in_progress in TodoWrite.

### 9.1 Create Workflow README

Create WORKFLOWS.md file at the location specified in Question 6.

**File Location** (based on Question 6 answer):
- ".claude/WORKFLOWS.md" → `.claude/WORKFLOWS.md`
- "WORKFLOWS.md" → `WORKFLOWS.md`
- "docs/WORKFLOWS.md" → `docs/WORKFLOWS.md`
- "README-WORKFLOWS.md" → `README-WORKFLOWS.md`

If the answer is "docs/WORKFLOWS.md", create the docs directory first:
```bash
mkdir -p docs
```

**Content** for the WORKFLOWS.md file:

```markdown
# Elixir Project Workflows

This project uses a standardized workflow system for research, planning, implementation, and quality assurance.

## Generated for: {{PROJECT_TYPE}} (Elixir)

---

## Available Commands

### /research

Research the codebase to answer questions and document existing implementations.

**Usage**:
```bash
/research "How does authentication work?"
/research "What is the API structure?"
```

**Output**: Research documents saved to `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`

---

### /plan

Create detailed implementation plans with success criteria.

**Usage**:
```bash
/plan "Add user profile page"
/plan "Refactor database layer"
```

**Output**: Plans saved to `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-description.md`

**Plan Structure**: {{PLANNING_STYLE}}

---

### /implement

Execute implementation plans with automated verification.

**Usage**:
```bash
/implement "2025-01-23-user-profile"
/implement   # Will prompt for plan selection
```

**Verification Commands**:
- Compile: `mix compile --warnings-as-errors`
- Test: `{{TEST_COMMAND}}`
- Format: `mix format --check-formatted`
{{#each QUALITY_TOOLS}}
- {{this}}
{{/each}}

---

### /qa

Validate implementation against success criteria and project quality standards.

**Usage**:
```bash
/qa                    # General health check
/qa "plan-name"        # Validate specific plan implementation
```

**Quality Gates**:
{{#each VALIDATION_CRITERIA}}
- {{this}}
{{/each}}

**Fix Workflow** (automatic): When critical issues are detected, `/qa` offers to automatically generate and execute a fix plan.

---

### Fix Workflow (Automatic)

When `/qa` detects critical issues, it automatically offers to generate a fix plan and execute it.

**Automatic Fix Flow**:
```
/qa → ❌ Critical issues detected
    ↓
"Generate fix plan?" → Yes
    ↓
/plan "Fix critical issues from QA report: ..."
    ↓
Fix plan created at {{DOCS_LOCATION}}/plans/plan-YYYY-MM-DD-fix-*.md
    ↓
"Execute fix plan?" → Yes
    ↓
/implement fix-plan-name
    ↓
/qa → Re-validation
    ↓
✅ Pass or iterate
```

**Manual Fix Flow**:
```
/qa → ❌ Critical issues detected → Decline auto-fix
    ↓
Review QA report manually
    ↓
Fix issues manually or create plan: /plan "Fix [specific issue]"
    ↓
/qa → Re-validation
```

**Oneshot with Auto-Fix**:

The `/oneshot` command automatically attempts fix workflows when QA fails:
```
/oneshot "Feature" → Research → Plan → Implement → QA
                                                     ↓
                                          ❌ Fails with critical issues
                                                     ↓
                                    "Auto-fix and re-validate?" → Yes
                                                     ↓
                        /plan "Fix..." → /implement fix → /qa
                                                     ↓
                                          ✅ Pass → Complete oneshot
```

**Benefits of Fix Workflow**:
- ✅ Reuses existing plan/implement infrastructure
- ✅ Fix plans documented like feature plans
- ✅ Handles complex multi-step fixes
- ✅ Full audit trail in `{{DOCS_LOCATION}}/plans/`
- ✅ Iterative: Can re-run `/qa` to generate new fix plans

---

## Workflow Sequence

The recommended workflow for new features:

1. **Research** (`/research`) - Understand current implementation
2. **Plan** (`/plan`) - Create detailed implementation plan
3. **Implement** (`/implement`) - Execute plan with verification
4. **QA** (`/qa`) - Validate against success criteria

---

## Customization

These commands were generated based on your project configuration. You can edit them directly:

- `.claude/commands/research.md`
- `.claude/commands/plan.md`
- `.claude/commands/implement.md`
- `.claude/commands/qa.md`
- `.claude/commands/oneshot.md`

To regenerate: `/meta:workflow-generator`

---

## Project Configuration

**Project Type**: {{PROJECT_TYPE}}
**Tech Stack**: Elixir
**Test Command**: {{TEST_COMMAND}}
**Documentation**: {{DOCS_LOCATION}}
**Planning Style**: {{PLANNING_STYLE}}

**Quality Tools**:
{{#each QUALITY_TOOLS}}
- {{this}}
{{/each}}
```

**Variable Substitution** for WORKFLOWS.md:
- `{{PROJECT_TYPE}}` → Answer from Question 1
- `{{DOCS_LOCATION}}` → Answer from Question 3
- `{{TEST_COMMAND}}` → Actual test command from Question 2
- `{{PLANNING_STYLE}}` → Answer from Question 5
- `{{QUALITY_TOOLS}}` → List from Question 4
- `{{VALIDATION_CRITERIA}}` → Expanded from Question 4

Use Write tool to create the file at the location determined above.

### 9.2 Create Documentation Directory

```bash
mkdir -p {{DOCS_LOCATION}}/research
mkdir -p {{DOCS_LOCATION}}/plans
mkdir -p {{DOCS_LOCATION}}/interview
```

Mark step 9 completed in TodoWrite.

---

## Step 10: Present Usage Instructions

Mark step 10 as in_progress in TodoWrite.

Present a comprehensive summary to the user:

```markdown
✅ Workflow commands generated successfully!

## Created Commands

```
.claude/
├── commands/
│   ├── interview.md    # Interactive context gathering
│   ├── research.md     # Research and document codebase
│   ├── plan.md         # Create implementation plans
│   ├── implement.md    # Execute plans with verification
│   ├── qa.md           # Validate implementation quality
│   └── oneshot.md      # Complete workflow in one command
{{WORKFLOWS_MD_LOCATION}}  # Complete workflow documentation
```

**Note**: Show the actual file path where WORKFLOWS.md was created based on Question 6 answer.

## Documentation Structure

```
{{DOCS_LOCATION}}/
├── interview/          # Interview context documents
├── research/           # Research documents
└── plans/              # Implementation plans
```

---

## Configuration Summary

**Project**: {{PROJECT_TYPE}} (Elixir)

**Commands Configured**:
- Compile: `mix compile --warnings-as-errors`
- Test: `{{TEST_COMMAND}}`
- Format: `mix format --check-formatted`

**Quality Tools Enabled**:
{{#each QUALITY_TOOLS}}
- {{this}}
{{/each}}

**Planning Style**: {{PLANNING_STYLE}}

---

## Quick Start

### 1. Research the Codebase

```bash
/research "How does [feature] work?"
```

This will:
- Spawn parallel research agents
- Document findings with file:line references
- Save to `{{DOCS_LOCATION}}/research-YYYY-MM-DD-topic.md`

### 2. Create an Implementation Plan

```bash
/plan "Add new feature X"
```

This will:
- Gather context via research
- Present design options
- Create phased plan with success criteria
- Save to `{{DOCS_LOCATION}}/plans/YYYY-MM-DD-feature-x.md`

### 3. Execute the Plan

```bash
/implement "2025-01-23-feature-x"
```

This will:
- Read the plan
- Execute phase by phase
- Run verification after each phase (`mix compile`, {{TEST_COMMAND}})
- Update checkmarks
- Pause for confirmation

### 4. Validate Implementation

```bash
/qa "feature-x"
```

This will:
- Run all quality gate checks
- Generate validation report
- Provide actionable feedback

---

## Workflow Example

**Scenario**: Adding a new Phoenix context

```bash
# 1. Research existing patterns
/research "How are contexts structured in this Phoenix app?"

# 2. Create implementation plan
/plan "Add Accounts context with user management"

# 3. Execute the plan
/implement "2025-01-23-accounts-context"

# 4. Validate implementation
/qa "accounts-context"
```

---

## Customization

All generated commands are fully editable. Customize them to match your exact workflow:

- **Add custom validation**: Edit `.claude/commands/qa.md`
- **Change plan structure**: Edit `.claude/commands/plan.md`
- **Add research sources**: Edit `.claude/commands/research.md`
- **Modify checkpoints**: Edit `.claude/commands/implement.md`

---

## Re-generate Commands

To regenerate these commands with different settings:

```bash
/workflow-generator
```

This will ask questions again and regenerate all commands.

---

## Documentation

Full workflow documentation: `{{WORKFLOWS_MD_LOCATION}}`

**Note**: Show the actual file path where WORKFLOWS.md was created.

---

## Next Steps

1. ✅ Try your first research: `/research "project structure"`
2. Read workflow docs: `{{WORKFLOWS_MD_LOCATION}}`
3. Customize commands as needed (edit `.claude/commands/*.md`)
4. Start your first planned feature!

**Note**: Replace `{{WORKFLOWS_MD_LOCATION}}` with the actual file path.

**Need help?** Each command has detailed instructions in its markdown file.
```

Mark step 10 completed in TodoWrite.

Mark all todos as completed and present final summary to user.

---

## Important Notes

### Generic Core Components

The generated commands maintain these universal patterns:
- TodoWrite for progress tracking
- Parallel agent spawning (finder, analyzer)
- YAML frontmatter with git metadata
- file:line reference format
- Documentation vs evaluation separation
- Success criteria framework (automated vs manual)

### Elixir-Specific Customizations

Commands are customized based on:
- Elixir project type (Phoenix, Library, CLI, Umbrella)
- Test commands (mix test, make test, custom)
- Documentation location preferences
- Quality tools enabled (Credo, Dialyzer, Sobelow, etc.)
- Planning methodology

### Extensibility

All generated commands are templates that users can:
- Edit directly to add project-specific logic
- Extend with additional validation
- Modify to match team conventions
- Enhance with custom agent types

### Agent Types Referenced

Generated commands use these standard agents:
- `finder`: Locate files and patterns
- `analyzer`: Deep technical analysis
- `general-purpose`: Flexible research tasks

Projects can define custom agents in `.claude/agents/` for specialized behavior.

---

## Error Handling

If generation fails at any step:
1. Report which step failed
2. Show the error
3. Offer to retry just that step
4. Provide manual instructions if needed

---

## Validation

After generating all commands:
1. Check that all files were created
2. Validate markdown structure
3. Verify template variables were replaced
4. Confirm documentation directory exists
5. Present final status to user
