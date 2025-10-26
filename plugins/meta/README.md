# meta

Meta plugin for generating Elixir project-specific workflow commands.

## Overview

The meta plugin provides a skill that generates a complete workflow system for Elixir projects. It creates customized `/research`, `/plan`, `/implement`, and `/qa` commands by asking questions about your Elixir project (Phoenix, Library, CLI, or Umbrella).

## Purpose

Instead of creating workflow commands manually for each Elixir project, the meta plugin:
1. **Asks questions** about your project (type, test strategy, quality tools)
2. **Generates customized commands** adapted to your Elixir workflow
3. **Creates documentation** explaining the workflow system
4. **Provides ready-to-use commands** that follow Elixir best practices

## Installation

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install meta@elixir
```

## Usage

### Generate Workflow Commands

```bash
/workflow-generator
```

This will:
1. Detect your project type and tech stack
2. Ask customization questions via interactive prompts
3. Generate four workflow commands:
   - `/research` - Research and document codebase
   - `/plan` - Create implementation plans with success criteria
   - `/implement` - Execute plans with automated verification
   - `/qa` - Validate implementation against quality gates
4. Create supporting documentation
5. Set up documentation directories

### What Gets Generated

```
.claude/
├── commands/
│   ├── research.md          # Customized for your file patterns
│   ├── plan.md              # Uses your build/test commands
│   ├── implement.md         # Includes your verification steps
│   ├── qa.md                # Enforces your quality gates
│   └── oneshot.md           # Complete workflow in one command

[WORKFLOWS.md location]      # Complete workflow documentation
                             # (You choose the location during generation)
```

Plus documentation directories at your chosen location (e.g., `.thoughts/`, `docs/`).

## Features

### Skill: workflow-generator

**Purpose**: Generate complete workflow system for Elixir projects

**Invocation**:
- Via command: `/workflow-generator`
- Directly: `Skill(command="workflow-generator")`

**Customization Questions**:
1. **Project Type**: Phoenix Application, Library/Package, CLI/Escript, or Umbrella Project
2. **Test Strategy**: mix test, make test, or custom script
3. **Documentation Location**: Where to save research and plans
4. **Quality Tools**: Credo, Dialyzer, Sobelow, ExDoc, mix_audit, Format check
5. **Planning Style**: Detailed phases, task checklist, or milestone-based
6. **WORKFLOWS.md Location**: Where to save workflow documentation (.claude/, project root, docs/, etc.)

**Generated Commands Are**:
- **Elixir-focused**: Work with Mix, ExUnit, and Elixir tooling
- **Customized**: Adapted to your specific test commands and quality tools
- **Editable**: Full markdown files you can modify
- **Best-practice**: Follow Elixir and Phoenix conventions

## Workflow System

The generated workflow follows a proven four-phase pattern:

### 1. Research (`/research`)
Document existing code without evaluation. Spawns parallel agents to:
- Find relevant files and patterns
- Analyze implementation details
- Extract architectural insights
- Save findings to research documents

### 2. Plan (`/plan`)
Create detailed implementation plans with:
- Phased execution structure
- Specific file changes with examples
- Success criteria (automated + manual)
- Design options and trade-offs

### 3. Implement (`/implement`)
Execute plans with built-in verification:
- Read plan and track progress
- Work phase by phase
- Run verification after each phase
- Update checkmarks
- Handle plan vs reality mismatches

### 4. QA (`/qa`)
Validate implementation quality:
- Run automated checks (tests, types, linting, security)
- Spawn validation agents
- Generate comprehensive report
- Provide actionable feedback

## Example Usage

### First-Time Setup

```bash
# Install meta plugin
/plugin install meta@elixir

# Generate workflow commands
/workflow-generator
```

Answer the questions, and you'll have a complete workflow system!

### Daily Workflow

```bash
# Research existing code
/research "How does authentication work?"

# Plan new feature
/plan "Add OAuth integration"

# Execute the plan
/implement "2025-01-23-oauth-integration"

# Validate implementation
/qa "oauth-integration"
```

## Customization

### Edit Generated Commands

All commands are standard markdown files. Customize them:

```bash
# Edit research command
vim .claude/commands/research.md

# Edit QA checks
vim .claude/commands/qa.md
```

### Regenerate Commands

To regenerate with different settings:

```bash
/workflow-generator
```

This will ask questions again and overwrite existing commands.

### Add Custom Agents

Create specialized agents for your project:

```bash
# Add custom agent
vim .claude/agents/database-analyzer.md
```

Then reference it in your customized commands.

## Why Meta Plugin?

### Before Meta Plugin

- Manually create workflow commands for each project
- Copy/paste from other projects and adapt
- Inconsistent patterns across projects
- Time-consuming setup

### After Meta Plugin

- One command generates complete workflow system
- Automatically adapted to project specifics
- Consistent best practices
- 5-minute setup

## Technical Details

### Convention-Based Skill Discovery

The workflow-generator skill is discovered automatically by Claude Code:
- Location: `plugins/meta/skills/workflow-generator/SKILL.md`
- No JSON registration required
- Available as `workflow-generator@elixir`

### Generic Core + Project Specifics

**Universal Patterns** (same across all projects):
- TodoWrite progress tracking
- Parallel agent spawning
- YAML frontmatter metadata
- file:line references
- Documentarian mode (no evaluation)
- Success criteria framework

**Customized Per Elixir Project**:
- Elixir project type (Phoenix, Library, CLI, Umbrella)
- Test commands (mix test, make test, custom)
- Documentation location
- Quality tools (Credo, Dialyzer, Sobelow, ExDoc, mix_audit)
- Planning methodology

### Elixir Project Types Supported

The workflow generator adapts to different Elixir project types:
- **Phoenix Application**: Full-stack web apps, APIs, LiveView apps
- **Library/Package**: Reusable Hex packages
- **CLI/Escript**: Command-line applications
- **Umbrella Project**: Multi-app umbrella projects

### Elixir Quality Tools Supported

Integrates with common Elixir quality tools:
- **Credo**: Static code analysis (`mix credo --strict`)
- **Dialyzer**: Type checking (`mix dialyzer`)
- **Sobelow**: Security scanning for Phoenix (`mix sobelow`)
- **ExDoc**: Documentation validation (`mix docs`)
- **mix_audit**: Dependency security audit (`mix deps.audit`)
- **Format check**: Code formatting validation (`mix format --check-formatted`)

## Comparison with Other Plugins

| Plugin | Purpose | Automated | User-Invoked |
|--------|---------|-----------|--------------|
| core | Auto-format, compile check | Yes (hooks) | No |
| credo | Static analysis | Yes (hooks) | No |
| **meta** | **Workflow generation** | **No** | **Yes (command/skill)** |

The meta plugin is unique:
- **Not a hook**: Doesn't trigger automatically
- **Elixir-focused**: Designed for Elixir/Phoenix projects
- **Generates other commands**: Creates customized workflow system
- **One-time setup**: Run once (or whenever you want to regenerate)

## Architecture

```
plugins/meta/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── skills/
│   └── workflow-generator/
│       └── SKILL.md             # Workflow generator skill
└── README.md                    # This file

.claude/commands/
└── workflow-generator.md        # Command to invoke skill
```

## Limitations

- **Overwrites existing commands**: Regeneration replaces `/research`, `/plan`, `/implement`, `/qa`
- **Template-based**: Generated commands are starting points, may need customization
- **No hooks**: Meta plugin doesn't use hooks (it generates commands, not automation)

## Contributing

To improve the workflow generator:

1. **Enhance questions**: Add more Elixir-specific customization options in `SKILL.md`
2. **Add quality tools**: Support additional Elixir/BEAM tools
3. **Improve templates**: Better default command structures for Elixir patterns
4. **Add examples**: Show more Elixir/Phoenix patterns in generated docs

## Support

- Report issues: https://github.com/bradleygolden/claude-marketplace-elixir/issues
- Source code: https://github.com/bradleygolden/claude-marketplace-elixir/tree/main/plugins/meta

## License

MIT
