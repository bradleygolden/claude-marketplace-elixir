---
description: Generate project-specific workflow commands (research, plan, implement, qa)
argument-hint: ""
allowed-tools: Skill
---

# Workflow Generator Command

This command invokes the workflow-generator skill to create a complete set of customized workflow commands for your project.

## What This Does

Generates four workflow commands tailored to your project:
- `/research` - Document codebase and answer questions
- `/plan` - Create detailed implementation plans
- `/implement` - Execute plans with verification
- `/qa` - Validate implementation quality

## Execution

Invoke the workflow-generator skill from the meta plugin:

```
Execute the workflow-generator@elixir skill, which will:

1. Discover project context (tech stack, build tools, structure)
2. Ask customization questions about your project
3. Generate customized workflow commands
4. Create supporting documentation
5. Provide usage instructions

The skill has full autonomy to ask questions using AskUserQuestion tool and generate all necessary files.
```

Invoke the skill:

```
Skill(command="workflow-generator")
```

## Important Notes

- **First-time setup**: This command generates the entire workflow system
- **Re-generation**: Run again to regenerate with different settings (will overwrite existing commands)
- **Customization**: After generation, you can manually edit generated commands in `.claude/commands/`
- **No arguments needed**: The skill handles everything interactively

## What Gets Generated

```
.claude/
├── commands/
│   ├── research.md          # Customized research command
│   ├── plan.md              # Customized planning command
│   ├── implement.md         # Customized implementation command
│   ├── qa.md                # Customized QA command
│   └── oneshot.md           # Complete workflow in one command
└── [your-docs-location]/    # Documentation directories
    ├── research/
    └── plans/

[WORKFLOWS.md location]      # Complete workflow documentation
                             # (You'll choose where during generation)
```

**Note**: You'll be asked where to save WORKFLOWS.md during generation (options include `.claude/`, project root, `docs/`, etc.)

## After Generation

Once complete, you can use your new commands:

```bash
/research "your question"
/plan "feature description"
/implement "plan-name"
/qa
```

See your WORKFLOWS.md file (location chosen during generation) for full documentation.
