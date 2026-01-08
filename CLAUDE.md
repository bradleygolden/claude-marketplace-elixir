# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **Claude Code plugin marketplace** for Elixir and BEAM ecosystem development. It provides automated development workflows through hooks that trigger on file edits and git operations.

## Architecture

### Plugin Marketplace Structure

```
.claude-plugin/
└── marketplace.json          # Marketplace metadata and plugin registry

plugins/
├── elixir/                   # Combined Elixir plugin (recommended)
│   ├── .claude-plugin/
│   │   └── plugin.json       # Plugin metadata
│   ├── hooks/
│   │   └── hooks.json        # Hook definitions
│   ├── lib/
│   │   └── utils.sh          # Shared utilities
│   ├── scripts/
│   │   ├── post-edit.sh      # PostToolUse hook
│   │   └── pre-commit.sh     # PreToolUse hook
│   ├── skills/               # Inherited from core
│   └── README.md
├── core/                     # Legacy: Core Elixir development
├── credo/                    # Legacy: Credo static analysis
├── ash/                      # Legacy: Ash Framework codegen
├── dialyzer/                 # Legacy: Dialyzer type analysis
├── ex_doc/                   # Legacy: ExDoc documentation
├── ex_unit/                  # Legacy: ExUnit testing
├── mix_audit/                # Legacy: Dependency security
├── precommit/                # Legacy: Phoenix precommit alias
└── sobelow/                  # Legacy: Security analysis

test/plugins/
├── elixir/                   # Elixir combined plugin tests
│   ├── README.md
│   ├── postedit-test/
│   ├── precommit-test/
│   └── test-elixir-hooks.sh
├── core/                     # Core plugin tests
├── credo/                    # Credo plugin tests
├── ash/                      # Ash plugin tests
└── ...                       # Other legacy plugin tests
```

### Key Concepts

**Marketplace (`marketplace.json`)**: Top-level descriptor that defines the marketplace namespace ("elixir"), version, and lists available plugins. The `pluginRoot` points to the plugins directory.

**Plugin (`plugin.json`)**: Each plugin has metadata (name, version, description, author) and a `hooks` field pointing to its hook definitions.

**Hooks (`hooks.json`)**: Define automated commands that execute in response to Claude Code events:
- `PostToolUse`: Runs after Edit/Write tools (e.g., auto-format, compile check)
- `PreToolUse`: Runs before tools execute (e.g., pre-commit validation before git commands)

### Hook Implementation Details

**Elixir plugin** (recommended) - Comprehensive Elixir development:

1. **Post-edit** (non-blocking, PostToolUse, 30s timeout): After editing `.ex`/`.exs` files:
   - Auto-formats the file
   - Checks for compilation errors
   - Runs Credo (if dependency present)
   - Checks Ash codegen (if dependency present)
   - Runs Sobelow security check (if dependency present)

2. **Pre-commit** (blocking, PreToolUse, 180s timeout): Before `git commit`:
   - Defers to `mix precommit` alias if present (Phoenix 1.8+)
   - Otherwise runs: format check, compile, unused deps, Credo, Ash codegen, Dialyzer, ExDoc, tests, mix_audit, Sobelow
   - Blocks commit on any failure

**Legacy plugins** - Individual tool plugins (deprecated):
- **Core**: Auto-format, compile check, pre-commit validation
- **Credo**: Static code analysis
- **Ash**: Ash Framework code generation
- **Dialyzer**: Static type analysis (120s timeout)
- **ExDoc**: Documentation quality validation (with locking for concurrent execution)
- **ExUnit**: Test running
- **mix_audit**: Dependency security
- **Precommit**: Phoenix precommit alias runner
- **Sobelow**: Security-focused static analysis

Hooks use `jq` to extract tool parameters and bash conditionals to match file patterns or commands. Output is sent to Claude (the LLM) via JSON with either `additionalContext` (non-blocking) or `permissionDecision: "deny"` (blocking).

### Skills

Skills provide specialized capabilities for Claude to use on demand, complementing automated hooks with user-invoked research and guidance.

**Core plugin** - Research and best practices skills:
1. **hex-docs-search** (core@elixir): Searches Hex package documentation with progressive fetch strategy
   - Searches local deps → fetched cache → fetches if needed → HexDocs API → web search
   - Stores fetched docs in `.hex-docs/` and source in `.hex-packages/`
   - Provides API documentation, function signatures, and usage examples
   - See `plugins/core/skills/hex-docs-search/SKILL.md`

2. **usage-rules** (core@elixir): Searches package-specific usage rules and best practices
   - Searches local deps → fetched cache → fetches if needed
   - Stores fetched rules in `.usage-rules/<package>-<version>/`
   - Provides coding conventions, patterns, and good/bad examples
   - Context-aware section extraction based on coding context
   - See `plugins/core/skills/usage-rules/SKILL.md`

**Skill Composition**:
Skills are designed to be **single-purpose** and **composed by agents/commands**:
- `usage-rules` provides conventions and patterns (how to use correctly)
- `hex-docs-search` provides API documentation (what's available)
- Agents can invoke both for comprehensive guidance ("best practices + API")
- Skills remain independent, composition happens through higher-level constructs

## Development Commands

### Testing the Marketplace Locally

```bash
# From Claude Code
/plugin marketplace add /Users/bradleygolden/Development/bradleygolden/claude
/plugin install core@elixir
```

### Testing from GitHub

```bash
# From Claude Code
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install core@elixir
```

### Validation

After making changes to marketplace or plugin JSON files, validate structure:
```bash
# Check marketplace.json is valid JSON
cat .claude-plugin/marketplace.json | jq .

# Check plugin.json is valid JSON
cat plugins/core/.claude-plugin/plugin.json | jq .

# Check hooks.json is valid JSON
cat plugins/core/hooks/hooks.json | jq .
```

### Testing Plugin Hooks

The repository includes an automated test suite for plugin hooks:

```bash
# Run all plugin tests
./test/run-all-tests.sh

# Run tests for a specific plugin
./test/plugins/core/test-core-hooks.sh
./test/plugins/credo/test-credo-hooks.sh
./test/plugins/ash/test-ash-hooks.sh
./test/plugins/dialyzer/test-dialyzer-hooks.sh

# Via Claude Code slash command
/qa test                   # All plugins
/qa test core              # Specific plugin
/qa test ash               # Specific plugin
```

**Test Framework**:
- `test/test-hook.sh` - Base testing utilities
- `test/run-all-tests.sh` - Main test runner
- `test/plugins/*/test-*-hooks.sh` - Plugin-specific test suites

**What the tests verify**:
- Hook exit codes (0 for success) and JSON permissionDecision for blocking
- Hook output patterns and JSON structure
- File type filtering (.ex, .exs, non-Elixir)
- Command filtering (git commit vs other commands)
- Blocking vs non-blocking behavior

See `test/README.md` for detailed documentation.

## Important Conventions

### Marketplace Namespace

The marketplace uses the namespace `elixir` (defined in `marketplace.json`). Plugins are referenced as `<plugin-name>@elixir` (e.g., `core@elixir`).

### Hook Matcher Patterns

- `PostToolUse` matcher `"Edit|Write|MultiEdit"` triggers on any file modification tool
- `PreToolUse` matcher `"Bash"` triggers before bash commands execute
- Hook commands extract tool parameters using `jq -r '.tool_input.<field>'`

### Version Management

Plugin and marketplace versions are **independent** and version for different reasons:

**Plugin Version** (`plugins/*/. claude-plugin/plugin.json`):
- Bump when plugin functionality changes (hooks, scripts, commands, agents, bug fixes, docs)
- Use semantic versioning: major.minor.patch
- Each plugin versions independently based on its own changes

**Marketplace Version** (`.claude-plugin/marketplace.json`):
- Bump ONLY when catalog structure changes (add/remove plugins, marketplace metadata, reorganization)
- NOT when individual plugin versions change
- NOT when plugin functionality changes

This follows standard package registry practices (npm, PyPI, Homebrew) where the registry version is independent of package versions. Think of it like a bookstore: book editions (plugin versions) change independently of catalog editions (marketplace version).

## File Modification Guidelines

**When editing JSON files**: Always maintain valid JSON structure. Use `jq` to validate after changes.

**When adding new plugins**:
1. Create plugin directory under `plugins/`
2. Add `.claude-plugin/plugin.json` with metadata inside the plugin directory
3. Add plugin to `plugins` array in `.claude-plugin/marketplace.json`
4. Create `README.md` documenting plugin features
5. Create test directory under `test/plugins/<plugin-name>/`

**When modifying hooks**:
1. Edit `plugins/<plugin-name>/hooks/hooks.json`
2. Update hook script in `plugins/<plugin-name>/scripts/` if needed
3. Run automated tests: `./test/plugins/<plugin-name>/test-<plugin-name>-hooks.sh`
4. Update plugin README.md to document hook behavior
5. Consider hook execution time and blocking behavior

## Hook Script Best Practices

**Exit Codes**:
- `0` - Success (allows operation to continue or suppresses output)
- `1` - Error (script failure)

**JSON Output Patterns**:
```bash
# Non-blocking with context (PostToolUse)
jq -n --arg context "$OUTPUT" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $context
  }
}'

# Suppress output when not relevant
jq -n '{"suppressOutput": true}'

# Blocking (PreToolUse) - JSON permissionDecision with exit 0
jq -n \
  --arg reason "$ERROR_MSG" \
  --arg msg "Commit blocked: validation failed" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    },
    "systemMessage": $msg
  }'
exit 0
```

**Common Patterns**:
- Project detection: Find Mix project root by traversing upward from file/directory
- Dependency detection: Use `grep -qE '\{:dependency_name' mix.exs` to check for specific dependency
- File filtering: Check file extensions with `grep -qE '\.(ex|exs)$'`
- Command filtering: Check for specific commands like `grep -q 'git commit'`
- Exit code handling: Check if variable is empty with `[[ -z "$VAR" ]]`, not `$?` after command substitution

## TodoWrite Best Practices

When using TodoWrite in slash commands and workflows:

**When to use**:
- Multi-step tasks with 3+ discrete actions
- Complex workflows requiring progress tracking
- User-requested lists of tasks
- Immediately when starting a complex command execution

**Required fields**:
- `content`: Imperative form describing what needs to be done (e.g., "Run tests")
- `activeForm`: Present continuous form shown during execution (e.g., "Running tests")
- `status`: One of `pending`, `in_progress`, `completed`

**Best practices**:
- Create todos at the START of command execution, not after
- Mark ONE task as `in_progress` at a time
- Mark tasks as `completed` IMMEDIATELY after finishing (don't batch)
- Break complex tasks into specific, actionable items
- Use clear, descriptive task names
- Update status in real-time as work progresses

**Example pattern**:
```javascript
[
  {"content": "Parse user input", "status": "completed", "activeForm": "Parsing user input"},
  {"content": "Research existing patterns", "status": "in_progress", "activeForm": "Researching existing patterns"},
  {"content": "Generate implementation plan", "status": "pending", "activeForm": "Generating implementation plan"}
]
```

## Agent Pattern for Token Efficiency

The marketplace uses specialized agents for token-efficient workflows:

**Finder Agent** (`.claude/agents/finder.md`):
- **Role**: Fast file location without reading (uses haiku model)
- **Tools**: Grep, Glob, Bash, Skill (NO Read tool)
- **Purpose**: Creates maps of WHERE files are, organized by purpose
- **Output**: File paths and locations, no code analysis

**Analyzer Agent** (`.claude/agents/analyzer.md`):
- **Role**: Deep code analysis with file reading (uses sonnet model)
- **Tools**: Read, Grep, Glob, Bash, Skill
- **Purpose**: Explains HOW things work by reading specific files
- **Output**: Execution flows, technical analysis with file:line references

**Token-Efficient Workflow Pattern**:
```
Step 1: Spawn finder → Locates relevant files (cheap, fast)
Step 2: Spawn analyzer → Reads files found by finder (expensive but targeted)
```

This pattern reduces token usage by 30-50% compared to having analyzer explore and read everything.

**When to Use**:
- Use **parallel** when researching independent aspects (no dependency)
- Use **sequential** (finder first, then analyzer) when analyzer needs file paths from finder

See `.claude/commands/qa.md` (lines 807-844) and `.claude/commands/research.md` (lines 56-73) for examples.

## Workflow System

The marketplace includes a comprehensive workflow system for development:

**Commands**:
- `/interview` - Gather context through interactive questioning
- `/research` - Research codebase with parallel agents
- `/plan` - Create detailed implementation plans
- `/implement` - Execute plans with verification
- `/qa` - Validate implementation quality
- `/oneshot` - Complete workflow (research → plan → implement → qa)

**Documentation Location**: All workflow artifacts saved to `.thoughts/`
```
.thoughts/
├── interview/          # Interview context documents
├── research/           # Research documents
├── plans/              # Implementation plans
└── [date]-*.md        # QA and oneshot reports
```

See `.claude/WORKFLOWS.md` for complete workflow documentation.

## Quality Gates

Before pushing changes, run:
```bash
/qa
```

This validates:
- JSON structure and validity
- Hook script correctness (exit codes, output patterns)
- Version management (marketplace and plugin versions)
- Documentation completeness
- Test coverage
- Comment quality (removes unnecessary, keeps critical)

## Git Commit Configuration

**Configured**: 2025-10-28

### Commit Message Format

**Format**: imperative-mood

#### Imperative Mood Template
```
<description>
```
Start with imperative verb: Add, Update, Fix, Remove, etc.
