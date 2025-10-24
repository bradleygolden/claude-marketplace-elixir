---
date: 2025-10-24 18:00:54 UTC
researcher: Bradley Golden
git_commit: 1f47f1209ff0f53fb09359821b92df446b0a979f
branch: ex_doc
repository: bradleygolden/claude-marketplace-elixir
topic: "ExDoc Integration for Plugin Marketplace"
tags: [research, exdoc, documentation, plugin-development]
status: complete
last_updated: 2025-10-24
last_updated_by: Bradley Golden
---

# Research: ExDoc Integration for Plugin Marketplace

**Date**: 2025-10-24 18:00:54 UTC
**Researcher**: Bradley Golden
**Git Commit**: 1f47f1209ff0f53fb09359821b92df446b0a979f
**Branch**: ex_doc
**Repository**: bradleygolden/claude-marketplace-elixir

## Research Question

"Please research the XCheck HexDocs library. You'll note that it has XDoc integration, or it has like a basically it supports XDoc. I want to have like a similar functionality in this project, so research this project as well. I want to support the idea of XDoc checking automatically. I'm not sure exactly though what capacity. If you look at other plugins, you can see how those are done. And I'm curious, you know, what would be recommended in this approach, what would be viable."

## Summary

The research revealed an important clarification: **ExCheck** (not XCheck) is a property-based testing library that **uses ExDoc** for its own documentation generation - it is not a documentation validation tool itself.

**ExDoc** is Elixir's official documentation generator that provides:
1. **`mix docs`** task - Generates HTML/EPUB documentation from code
2. **`--warnings-as-errors`** flag - Exits with non-zero code if documentation warnings occur
3. **Validation capabilities** - Detects undefined references, broken links, missing files
4. **Quality checking** - Ensures documentation stays in sync with code

For this plugin marketplace, an **ExDoc plugin** could implement documentation validation through:
- **PostToolUse hooks** (non-blocking): Check for doc warnings after editing `.ex`/`.exs` files
- **PreToolUse hooks** (blocking): Validate docs before git commits using `mix docs --warnings-as-errors`

This follows the same patterns as existing plugins (Core, Credo, Ash, Dialyzer, Sobelow).

## Detailed Findings

### ExCheck Library Analysis

**What ExCheck Is**: `/Users/bradleygolden/Development/bradleygolden/claude/thoughts/research/2025-10-24-exdoc-integration-research.md:35`
- Property-based testing library for Elixir
- Implements QuickCheck-style testing
- Wraps Erlang's **triq** library
- Integrates with ExUnit test framework

**Relationship to ExDoc**: `/Users/bradleygolden/Development/bradleygolden/claude/thoughts/research/2025-10-24-exdoc-integration-research.md:40`
- ExCheck uses ExDoc as a **development dependency** for generating its own API documentation
- Added ExDoc support in version 0.5.1 (2016)
- Uses standard `@moduledoc` and `@doc` annotations
- ExDoc processes these to create HTML documentation at https://hexdocs.pm/excheck

**Key Finding**: ExCheck is a **consumer** of ExDoc, not a documentation validation tool. The "XDoc integration" refers to ExCheck using ExDoc to document itself, not to validate documentation quality.

### ExDoc Mix Tasks and Capabilities

#### 1. `mix docs` Task

**Purpose**: Generates static HTML and/or EPUB documentation from source code

**Key Validation Capabilities**:

1. **Undefined Reference Detection**
   - Warns when documentation references non-existent `Mod.fun/arity`
   - Catches typos in module, function, type, or callback references
   - Validates cross-references within project and dependencies
   - Example: `warning: documentation references "SomeModule.function/2" but it does not exist`

2. **File Reference Validation**
   - Warns when documentation links to non-existent files
   - Example: `warning: documentation references file "guides/missing.md" but it does not exist`

3. **Dependency Validation**
   - Warns when extra links target applications not in dependencies
   - Validates dependency documentation URLs

4. **Asset Validation**
   - Image format validation (PNG, JPEG, SVG only)
   - EPUB cover dimension recommendations
   - Unknown media type handling

5. **Configuration Validation**
   - Validates language tags (BCP 47)
   - Validates redirect targets exist
   - Checks for required fields

**Exit Code Behavior**:
- Exit 0: Success (no errors, or warnings without `--warnings-as-errors`)
- Exit 1: Failure (warnings with `--warnings-as-errors` flag, or fatal errors)

**Critical Flag for CI/CD**: `--warnings-as-errors`
- Converts any warning into a failure (exit code 1)
- Designed for continuous integration pipelines
- Enforces documentation quality gates

**Example Usage**:
```bash
# Development - shows warnings but succeeds
mix docs

# CI/CD - fails on any warnings
mix docs --warnings-as-errors
```

#### 2. Warning Suppression Configuration

ExDoc provides configuration options to suppress specific warnings:

```elixir
# In mix.exs under :docs key
docs: [
  skip_undefined_reference_warnings_on: [
    "CHANGELOG.md",              # Skip for files
    "MyApp.DeprecatedModule",    # Skip for modules
    "MyApp.Module.function/2"    # Skip for functions
  ],

  skip_code_autolink_to: ["CustomType", "SpecialTerm"]
]
```

### Existing Plugin Implementation Patterns

All plugins in the marketplace follow consistent patterns documented in:
- Core plugin: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/core/`
- Credo plugin: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/credo/`
- Ash plugin: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/ash/`
- Dialyzer plugin: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/dialyzer/`
- Sobelow plugin: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/sobelow/`

#### Hook Pattern 1: PostToolUse (Non-Blocking Informational)

**Used by**: Core, Credo, Ash, Sobelow

**Trigger**: After Edit/Write/MultiEdit tools execute
**Purpose**: Provide informational feedback to Claude without blocking execution
**Timeout**: 15-30 seconds

**Pattern Structure** (`hooks.json`):
```json
{
  "PostToolUse": [
    {
      "matcher": "Edit|Write|MultiEdit",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/post-edit-check.sh",
          "timeout": 30
        }
      ]
    }
  ]
}
```

**Script Pattern**:
1. Read stdin JSON with tool parameters
2. Extract `file_path` using `jq`
3. Filter for `.ex`/`.exs` files
4. Find Mix project root
5. Run validation tool (e.g., `mix docs`)
6. Output JSON with `additionalContext` or `suppressOutput`
7. Exit 0 (never blocks)

**Example**: Credo post-edit-check (`/Users/bradleygolden/Development/bradleygolden/claude/plugins/credo/scripts/post-edit-check.sh:40-68`)
```bash
# Run Credo on specific file
CREDO_OUTPUT=$(cd "$PROJECT_ROOT" && mix credo "$FILE_PATH" 2>&1)
CREDO_EXIT_CODE=$?

# If issues found, send context to Claude
if [ $CREDO_EXIT_CODE -ne 0 ]; then
  jq -n --arg context "$CONTEXT" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $context
    }
  }'
else
  jq -n '{"suppressOutput": true}'
fi

exit 0
```

#### Hook Pattern 2: PreToolUse (Blocking Validation)

**Used by**: All 5 plugins (Core, Credo, Ash, Dialyzer, Sobelow)

**Trigger**: Before Bash tool executes (specifically before `git commit`)
**Purpose**: Block git commits if validation fails
**Timeout**: 30-120 seconds

**Pattern Structure** (`hooks.json`):
```json
{
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit-check.sh",
          "timeout": 45
        }
      ]
    }
  ]
}
```

**Script Pattern**:
1. Read stdin JSON with tool parameters
2. Extract `command` and `cwd` using `jq`
3. Filter for `git commit` commands
4. Find Mix project root
5. Run validation tool
6. If validation fails: output to stderr and exit 2 (BLOCKS commit)
7. If validation passes: exit 0 (allows commit)

**Example**: Credo pre-commit-check (`/Users/bradleygolden/Development/bradleygolden/claude/plugins/credo/scripts/pre-commit-check.sh:42-68`)
```bash
# Run Credo strict mode
CREDO_OUTPUT=$(cd "$PROJECT_ROOT" && mix credo --strict 2>&1)
CREDO_EXIT_CODE=$?

# Block commit if issues found
if [ $CREDO_EXIT_CODE -ne 0 ]; then
  echo "$OUTPUT" >&2
  exit 2  # BLOCKS commit
else
  jq -n '{"suppressOutput": true}'
  exit 0  # Allows commit
fi
```

#### Common Implementation Patterns

**Pattern A: Input Extraction** (all hooks)
```bash
INPUT=$(cat) || exit 1
FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path' 2>/dev/null) || exit 1

if [[ "$FILE_PATH" == "null" ]] || [[ -z "$FILE_PATH" ]]; then
  exit 0
fi
```

**Pattern B: File Type Filtering** (PostToolUse hooks)
```bash
if ! echo "$FILE_PATH" | grep -qE '\.(ex|exs)$'; then
  exit 0
fi
```

**Pattern C: Command Filtering** (PreToolUse hooks)
```bash
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi
```

**Pattern D: Project Root Detection** (all hooks)
```bash
find_mix_project_root() {
  local dir=$(dirname "$1")
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_mix_project_root "$FILE_PATH")
if [ $? -ne 0 ]; then
  exit 0
fi
```

**Pattern E: Dependency Detection** (tool-specific plugins)
```bash
if ! grep -qE '\{:dependency_name' "$PROJECT_ROOT/mix.exs" 2>/dev/null; then
  exit 0
fi
```

**Pattern F: Output Truncation** (context-providing hooks)
```bash
TOTAL_LINES=$(echo "$OUTPUT" | wc -l)
MAX_LINES=50

if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
  TRUNCATED_OUTPUT=$(echo "$OUTPUT" | head -n $MAX_LINES)
  OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]"
fi
```

## Code References

### ExDoc Mix Task Documentation
- Official docs: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
- Source code: https://github.com/elixir-lang/ex_doc/blob/main/lib/mix/tasks/docs.ex
- Hex.Docs task: https://hexdocs.pm/hex/Mix.Tasks.Hex.Docs.html

### Plugin Marketplace Structure
- Marketplace config: `/Users/bradleygolden/Development/bradleygolden/claude/.claude-plugin/marketplace.json`
- Plugin pattern: `plugins/<plugin-name>/.claude-plugin/plugin.json`
- Hook definitions: `plugins/<plugin-name>/hooks/hooks.json`
- Hook scripts: `plugins/<plugin-name>/scripts/*.sh`

### Existing Plugin Hooks
- Core auto-format: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/core/scripts/auto-format.sh`
- Core compile-check: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/core/scripts/compile-check.sh`
- Core pre-commit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/core/scripts/pre-commit-check.sh`
- Credo post-edit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/credo/scripts/post-edit-check.sh`
- Credo pre-commit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/credo/scripts/pre-commit-check.sh`
- Ash post-edit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/ash/scripts/post-edit-check.sh`
- Ash pre-commit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/ash/scripts/pre-commit-check.sh`
- Dialyzer pre-commit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/dialyzer/scripts/pre-commit-check.sh`
- Sobelow post-edit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/sobelow/scripts/post-edit-check.sh`
- Sobelow pre-commit: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/sobelow/scripts/pre-commit-check.sh`

## Implementation Patterns

### Pattern 1: PostToolUse Documentation Check (Non-Blocking)

**Use Case**: After editing Elixir files, check for documentation issues and inform Claude

**Hook Configuration** (`plugins/ex_doc/hooks/hooks.json`):
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/post-edit-check.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Script Implementation** (`plugins/ex_doc/scripts/post-edit-check.sh`):
```bash
#!/bin/bash
set -e

INPUT=$(cat) || exit 1

FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path' 2>/dev/null) || exit 1

if [[ "$FILE_PATH" == "null" ]] || [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only process .ex and .exs files
if ! echo "$FILE_PATH" | grep -qE '\.(ex|exs)$'; then
  exit 0
fi

# Find Mix project root
find_mix_project_root() {
  local dir=$(dirname "$1")
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_mix_project_root "$FILE_PATH")
if [ $? -ne 0 ]; then
  exit 0
fi

cd "$PROJECT_ROOT"

# Check if ExDoc is in dependencies
if ! grep -qE '\{:ex_doc' mix.exs 2>/dev/null; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Run mix docs with warnings-as-errors to catch issues
DOCS_OUTPUT=$(mix docs --warnings-as-errors 2>&1)
DOCS_EXIT_CODE=$?

# If documentation issues found, send context to Claude
if [ $DOCS_EXIT_CODE -ne 0 ]; then
  TOTAL_LINES=$(echo "$DOCS_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$DOCS_OUTPUT" | head -n $MAX_LINES)
    CONTEXT="Documentation validation for $FILE_PATH:

$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix docs --warnings-as-errors' to see the full output."
  else
    CONTEXT="Documentation validation for $FILE_PATH:

$DOCS_OUTPUT"
  fi

  jq -n \
    --arg context "$CONTEXT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": $context
      }
    }'
else
  jq -n '{"suppressOutput": true}'
fi

exit 0
```

**Behavior**:
- Runs after each Edit/Write operation on `.ex`/`.exs` files
- Executes `mix docs --warnings-as-errors` to detect documentation issues
- If issues found: Sends context to Claude via `additionalContext`
- If no issues: Suppresses output with `suppressOutput`
- Never blocks execution (always exits 0)
- Truncates output to 30 lines max

**Detected Issues**:
- Undefined reference warnings (e.g., `@doc` referencing non-existent functions)
- Missing file references in documentation
- Broken links
- Invalid configuration
- Asset validation issues

### Pattern 2: PreToolUse Documentation Validation (Blocking)

**Use Case**: Before git commits, validate documentation quality and block if issues found

**Hook Configuration** (`plugins/ex_doc/hooks/hooks.json`):
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit-check.sh",
            "timeout": 45
          }
        ]
      }
    ]
  }
}
```

**Script Implementation** (`plugins/ex_doc/scripts/pre-commit-check.sh`):
```bash
#!/bin/bash
set -e

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ "$COMMAND" == "null" ]] || [[ -z "$COMMAND" ]]; then
  exit 0
fi

if [[ "$CWD" == "null" ]] || [[ -z "$CWD" ]]; then
  exit 0
fi

# Only run on git commit commands
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Find Mix project root
find_mix_project_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_mix_project_root "$CWD")
if [ $? -ne 0 ]; then
  exit 0
fi

cd "$PROJECT_ROOT"

# Check if ExDoc is in dependencies
if ! grep -qE '\{:ex_doc' mix.exs 2>/dev/null; then
  exit 0
fi

# Run documentation validation
mix docs --warnings-as-errors 2>&1 >&2
DOCS_EXIT_CODE=$?

# Block commit if documentation issues found
if [ $DOCS_EXIT_CODE -ne 0 ]; then
  exit 2  # BLOCKS commit
fi

exit 0  # Allows commit
```

**Behavior**:
- Runs before `git commit` executes
- Executes `mix docs --warnings-as-errors`
- If validation fails: Outputs errors to stderr and exits 2 (BLOCKS commit)
- If validation passes: Exits 0 (allows commit)
- Only runs if `{:ex_doc` found in `mix.exs`

**Quality Gate**:
- Ensures no undefined references
- Ensures no broken links
- Ensures all documentation is valid
- Prevents committing code with documentation issues

### Pattern 3: Hybrid Approach (Recommended)

**Rationale**: Combine both PostToolUse and PreToolUse hooks for comprehensive coverage

**Benefits**:
1. **PostToolUse** provides immediate feedback after editing
   - Non-blocking - doesn't interrupt workflow
   - Claude sees issues and can suggest fixes
   - Fast feedback loop

2. **PreToolUse** enforces quality gates before commits
   - Blocking - prevents committing broken docs
   - Final validation before code enters repository
   - Ensures consistency in codebase

**Hook Configuration** (`plugins/ex_doc/hooks/hooks.json`):
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/post-edit-check.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit-check.sh",
            "timeout": 45
          }
        ]
      }
    ]
  }
}
```

**Workflow**:
```
1. User edits MyModule.ex with Claude
   ↓
2. PostToolUse hook runs mix docs --warnings-as-errors
   ↓
3a. If issues found → Claude sees context, suggests fixes
3b. If no issues → Silent success
   ↓
4. User continues editing until satisfied
   ↓
5. User requests: git commit -m "message"
   ↓
6. PreToolUse hook runs mix docs --warnings-as-errors
   ↓
7a. If issues found → Commit BLOCKED, user sees error
7b. If no issues → Commit proceeds
```

### Pattern 4: Performance Optimization

**Issue**: Running full `mix docs` on every file edit can be slow for large projects

**Optimization Strategy**: Check only if documentation-related changes occurred

**Optimized Post-Edit Check**:
```bash
# Only run docs check if:
# 1. File contains @moduledoc or @doc
# 2. File is in lib/ directory (not test/)

# Quick content check
if ! grep -qE '@(moduledoc|doc)' "$FILE_PATH"; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Check if in lib directory (not test)
if echo "$FILE_PATH" | grep -qE '/test/'; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Now run docs check
DOCS_OUTPUT=$(mix docs --warnings-as-errors 2>&1)
# ... rest of logic
```

**Benefit**: Reduces unnecessary doc generation when editing test files or files without documentation

### Pattern 5: Selective Validation

**Use Case**: Some projects may not want strict documentation validation

**Configuration Option**: Add a config flag to control behavior

**In mix.exs**:
```elixir
def project do
  [
    # ... other config

    # ExDoc plugin configuration
    ex_doc_plugin: [
      # Enable/disable post-edit checking
      check_on_edit: true,

      # Enable/disable pre-commit blocking
      block_commits: true,

      # Max lines of output
      max_output_lines: 30
    ]
  ]
end
```

**Script reads config**:
```bash
# Check if post-edit checking is enabled
CHECK_ENABLED=$(cd "$PROJECT_ROOT" && mix run -e '
  config = Mix.Project.config()[:ex_doc_plugin] || []
  IO.puts(Keyword.get(config, :check_on_edit, true))
' 2>/dev/null)

if [[ "$CHECK_ENABLED" != "true" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi
```

## Pattern Examples

### Example 1: Core Plugin Compile Check Pattern

**Reference**: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/core/scripts/compile-check.sh:45-80`

**Pattern**:
- Runs `mix compile --warnings-as-errors`
- Captures output and exit code
- If compilation fails: Sends truncated error context to Claude
- If compilation succeeds: Suppresses output

**Key Characteristics**:
- PostToolUse (non-blocking)
- Always exits 0
- Provides informational context
- Truncates to 50 lines

### Example 2: Credo Plugin Pre-Commit Pattern

**Reference**: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/credo/scripts/pre-commit-check.sh:42-68`

**Pattern**:
- Filters for `git commit` commands
- Runs `mix credo --strict`
- If issues found: Outputs to stderr and exits 2 (blocks)
- If no issues: Exits 0 (allows commit)

**Key Characteristics**:
- PreToolUse (blocking)
- Exit code 2 blocks commits
- Direct stderr output
- Truncates to 30 lines

### Example 3: Ash Plugin Dependency Detection

**Reference**: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/ash/scripts/post-edit-check.sh:45-49`

**Pattern**:
- Checks for `{:ash` in mix.exs
- If not found: Suppresses output and exits early
- If found: Proceeds with validation

**Key Characteristics**:
- Graceful degradation
- Only runs on Ash projects
- Silent exit when not applicable

### Example 4: Dialyzer Long Timeout

**Reference**: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/dialyzer/hooks/hooks.json:11`

**Pattern**:
- Uses 120 second timeout (longest of all plugins)
- Accounts for Dialyzer's analysis time

**Key Characteristics**:
- Appropriate timeout for tool complexity
- Prevents premature termination

### Example 5: Sobelow JSON Parsing

**Reference**: `/Users/bradleygolden/Development/bradleygolden/claude/plugins/sobelow/scripts/post-edit-check.sh:44-88`

**Pattern**:
- Runs `mix sobelow --format json`
- Parses JSON output with jq
- Checks for findings in high/medium/low confidence
- Blocks based on finding existence, not just exit code

**Key Characteristics**:
- Structured output parsing
- More nuanced than simple exit code checking
- Provides detailed finding information

## Viable Approaches for ExDoc Plugin

### Approach 1: Minimal Implementation (Post-Edit Only)

**Structure**:
- Single PostToolUse hook
- Runs `mix docs --warnings-as-errors` after edits
- Provides informational feedback only
- Never blocks workflow

**Pros**:
- Simple to implement
- Non-intrusive
- Provides immediate feedback

**Cons**:
- No enforcement mechanism
- Documentation issues can still be committed
- Relies on developer response to warnings

**Best For**: Projects that want gentle documentation reminders without enforcement

### Approach 2: Quality Gate Implementation (Pre-Commit Only)

**Structure**:
- Single PreToolUse hook
- Runs `mix docs --warnings-as-errors` before git commit
- Blocks commits if documentation issues found

**Pros**:
- Strong quality enforcement
- Prevents bad documentation from entering repository
- Simple implementation

**Cons**:
- No immediate feedback during editing
- Can surprise users at commit time
- Might slow down commit workflow

**Best For**: Projects with strict documentation requirements and mature codebases

### Approach 3: Full Coverage Implementation (Post-Edit + Pre-Commit)

**Structure**:
- PostToolUse hook for immediate feedback
- PreToolUse hook for commit blocking
- Both run `mix docs --warnings-as-errors`

**Pros**:
- Best of both worlds
- Immediate feedback + enforcement
- Matches patterns of other plugins (Credo, Ash)
- Most comprehensive coverage

**Cons**:
- More complex implementation (2 scripts)
- Runs docs twice (edit-time + commit-time)
- May feel redundant if docs are slow to generate

**Best For**: Most projects - provides flexibility and comprehensive coverage

### Approach 4: Smart/Optimized Implementation

**Structure**:
- PostToolUse hook with smart filtering
- PreToolUse hook for final validation
- Optimizations:
  - Only check files with `@moduledoc` or `@doc`
  - Skip test files
  - Cache results to avoid redundant checks
  - Configurable via mix.exs

**Pros**:
- Performance optimized
- Still provides coverage
- User-configurable
- Reduces unnecessary runs

**Cons**:
- Most complex to implement
- Requires careful testing
- Caching logic can be tricky

**Best For**: Large projects with slow doc generation, or projects that want fine-grained control

## Recommended Approach

**Recommendation**: **Approach 3 - Full Coverage Implementation**

**Rationale**:
1. **Consistency with existing plugins**: All other quality-focused plugins (Credo, Ash, Sobelow) use both PostToolUse and PreToolUse hooks
2. **Comprehensive coverage**: Provides both immediate feedback and enforcement
3. **Proven pattern**: The pattern is well-established and tested in this marketplace
4. **Balance**: Non-blocking feedback during development, blocking validation before commit
5. **User experience**: Matches user expectations from other plugins

**Implementation Structure**:
```
plugins/ex_doc/
├── .claude-plugin/
│   └── plugin.json          # Metadata
├── hooks/
│   └── hooks.json           # Both PostToolUse and PreToolUse hooks
├── scripts/
│   ├── post-edit-check.sh   # Non-blocking docs check
│   └── pre-commit-check.sh  # Blocking docs validation
└── README.md                # Plugin documentation
```

**Hooks Configuration**:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/post-edit-check.sh",
            "timeout": 30
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/pre-commit-check.sh",
            "timeout": 45
          }
        ]
      }
    ]
  }
}
```

**Key Features**:
- Dependency detection: Check for `{:ex_doc` in mix.exs
- File type filtering: Only check `.ex` and `.exs` files
- Command filtering: Only run pre-commit on `git commit`
- Output truncation: Limit to 30 lines max
- Exit code semantics: 0 for success/allow, 2 for block
- JSON output: Use `additionalContext` for PostToolUse, stderr for PreToolUse

## Implementation Checklist

When implementing an ExDoc plugin following the recommended approach:

### 1. Plugin Structure
- [ ] Create `plugins/ex_doc/` directory
- [ ] Create `.claude-plugin/plugin.json` with metadata
- [ ] Create `hooks/hooks.json` with both hook types
- [ ] Create `scripts/post-edit-check.sh`
- [ ] Create `scripts/pre-commit-check.sh`
- [ ] Create `README.md` with plugin documentation
- [ ] Set execute permissions on scripts: `chmod +x scripts/*.sh`

### 2. Hook Configuration
- [ ] Define PostToolUse hook with matcher `"Edit|Write|MultiEdit"`
- [ ] Define PreToolUse hook with matcher `"Bash"`
- [ ] Set appropriate timeouts (30s for post-edit, 45s for pre-commit)
- [ ] Reference scripts via `${CLAUDE_PLUGIN_ROOT}/scripts/`

### 3. Post-Edit Script
- [ ] Implement stdin reading and JSON parsing
- [ ] Extract `file_path` using `jq`
- [ ] Validate extracted values (not null, not empty)
- [ ] Filter for `.ex` and `.exs` files
- [ ] Implement `find_mix_project_root()` function
- [ ] Check for `{:ex_doc` dependency in mix.exs
- [ ] Run `mix docs --warnings-as-errors`
- [ ] Capture output and exit code
- [ ] Implement output truncation (30 lines max)
- [ ] Output JSON with `additionalContext` if issues found
- [ ] Output JSON with `suppressOutput` if no issues
- [ ] Always exit 0 (never block)

### 4. Pre-Commit Script
- [ ] Implement stdin reading and JSON parsing
- [ ] Extract `command` and `cwd` using `jq`
- [ ] Validate extracted values
- [ ] Filter for `git commit` commands
- [ ] Implement `find_mix_project_root()` function
- [ ] Check for `{:ex_doc` dependency in mix.exs
- [ ] Run `mix docs --warnings-as-errors`
- [ ] Redirect output to stderr (`2>&1 >&2`)
- [ ] Exit 2 if validation fails (blocks commit)
- [ ] Exit 0 if validation passes (allows commit)

### 5. Testing
- [ ] Create test directory: `test/plugins/ex_doc/`
- [ ] Create test script: `test/plugins/ex_doc/test-ex-doc-hooks.sh`
- [ ] Test post-edit hook with valid file
- [ ] Test post-edit hook with file containing doc issues
- [ ] Test post-edit hook with non-Elixir file
- [ ] Test pre-commit hook with valid commit
- [ ] Test pre-commit hook with doc issues
- [ ] Test pre-commit hook with non-git-commit command
- [ ] Test dependency detection (with and without ex_doc)
- [ ] Verify exit codes (0 for success, 2 for blocking)
- [ ] Verify JSON output format
- [ ] Verify output truncation

### 6. Documentation
- [ ] Write README.md with plugin purpose
- [ ] Document installation steps
- [ ] Document hook behavior (PostToolUse and PreToolUse)
- [ ] Document detected issues (undefined refs, broken links, etc.)
- [ ] Document configuration options (if any)
- [ ] Document exit codes
- [ ] Provide examples

### 7. Marketplace Integration
- [ ] Add plugin entry to `.claude-plugin/marketplace.json`
- [ ] Update marketplace version
- [ ] Validate JSON structure: `cat .claude-plugin/marketplace.json | jq .`
- [ ] Validate plugin.json: `cat plugins/ex_doc/.claude-plugin/plugin.json | jq .`
- [ ] Validate hooks.json: `cat plugins/ex_doc/hooks/hooks.json | jq .`

### 8. Quality Assurance
- [ ] Run `/qa test ex_doc` to validate implementation
- [ ] Test in real Elixir project with ExDoc
- [ ] Test in project without ExDoc (should skip gracefully)
- [ ] Verify no false positives
- [ ] Verify accurate issue detection
- [ ] Check performance with large projects

## Related Research

- Hook execution system: Documented in sub-agent findings
- Existing plugin patterns: All 5 plugins analyzed (Core, Credo, Ash, Dialyzer, Sobelow)
- ExDoc capabilities: Full mix task analysis completed
- Exit code semantics: 0 (success/allow), 2 (block)

## Open Questions

1. **Performance**: Should we implement smart filtering (only check files with `@doc`) or always run full `mix docs`?
   - Trade-off: Speed vs completeness
   - Current pattern (Credo, Ash): Run tool unconditionally
   - Recommendation: Start simple (always run), optimize if needed

2. **Timeout**: Is 30s/45s appropriate for `mix docs`?
   - Depends on project size
   - Core compile-check uses 20s, Credo uses 30s, Dialyzer uses 120s
   - Recommendation: Start with 30s/45s, adjust based on testing

3. **Output Format**: Should we parse specific warning types or show raw output?
   - Current pattern: Show raw output from tool
   - Alternative: Parse and categorize (like Sobelow)
   - Recommendation: Start with raw output (simpler), enhance later if needed

4. **Configuration**: Should users be able to disable hooks via mix.exs?
   - Current plugins: No configuration mechanism
   - Could add project-level config
   - Recommendation: Start without config, add if requested

5. **Scope**: Should we check only modified files or entire project?
   - PostToolUse has access to specific file
   - PreToolUse runs on entire project
   - `mix docs` always checks entire project
   - Recommendation: Keep current behavior (full project check)

6. **Warning Suppression**: Should we support ExDoc's `skip_undefined_reference_warnings_on`?
   - ExDoc already handles this via mix.exs config
   - Our hook just runs `mix docs`
   - Recommendation: Rely on ExDoc's native suppression, don't duplicate

## Summary

This research establishes that an **ExDoc plugin** for the Claude Code plugin marketplace should:

1. **Use both PostToolUse and PreToolUse hooks** (Approach 3 - Full Coverage)
2. **Follow existing plugin patterns** (Core, Credo, Ash, Dialyzer, Sobelow)
3. **Run `mix docs --warnings-as-errors`** to detect documentation issues
4. **Provide non-blocking feedback** after edits via JSON `additionalContext`
5. **Block commits** if documentation validation fails via exit code 2
6. **Implement standard patterns**:
   - Input extraction via `jq`
   - File type filtering (`.ex`, `.exs`)
   - Command filtering (`git commit`)
   - Project root detection
   - Dependency detection (`{:ex_doc`)
   - Output truncation (30 lines)
   - Exit code semantics (0 = success/allow, 2 = block)

The plugin will ensure documentation quality by:
- Catching undefined references to non-existent modules/functions
- Detecting broken file links in documentation
- Validating configuration
- Preventing documentation issues from being committed

This approach is viable, proven, and consistent with the marketplace's existing plugin ecosystem.
