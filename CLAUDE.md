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
├── core/                     # Core Elixir development plugin
│   ├── .claude-plugin/
│   │   └── plugin.json       # Plugin metadata
│   ├── hooks/
│   │   └── hooks.json        # Hook definitions
│   └── README.md             # Plugin documentation
└── credo/                    # Credo static analysis plugin
    ├── .claude-plugin/
    │   └── plugin.json
    ├── hooks/
    │   └── hooks.json
    ├── scripts/
    │   ├── post-edit-check.sh
    │   └── pre-commit-check.sh
    └── README.md

test/plugins/
├── core/                     # Core plugin tests
│   ├── README.md
│   ├── autoformat-test/
│   ├── compile-test/
│   └── precommit-test/
└── credo/                    # Credo plugin tests
    ├── README.md
    ├── postedit-test/
    └── precommit-test/
```

### Key Concepts

**Marketplace (`marketplace.json`)**: Top-level descriptor that defines the marketplace namespace ("elixir"), version, and lists available plugins. The `pluginRoot` points to the plugins directory.

**Plugin (`plugin.json`)**: Each plugin has metadata (name, version, description, author) and a `hooks` field pointing to its hook definitions.

**Hooks (`hooks.json`)**: Define automated commands that execute in response to Claude Code events:
- `PostToolUse`: Runs after Edit/Write tools (e.g., auto-format, compile check)
- `PreToolUse`: Runs before tools execute (e.g., pre-commit validation before git commands)

### Hook Implementation Details

The core plugin implements three critical workflows:

1. **Auto-format** (non-blocking, PostToolUse): After editing `.ex`/`.exs` files, runs `mix format {{file_path}}`
2. **Compile check** (informational, PostToolUse): After editing, runs `mix compile --warnings-as-errors` and provides compilation errors as context to Claude via `additionalContext`
3. **Pre-commit validation** (blocking, PreToolUse): Before `git commit`, validates formatting, compilation, and unused deps, blocking commits on failures

Hooks use `jq` to extract tool parameters and bash conditionals to match file patterns or commands. Output is sent to Claude (the LLM) either via JSON `additionalContext` (non-blocking) or stderr with exit code 2 (blocking).

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

# Via Claude Code slash command
/test-marketplace          # All plugins
/test-marketplace core     # Specific plugin
```

**Test Framework**:
- `test/test-hook.sh` - Base testing utilities
- `test/run-all-tests.sh` - Main test runner
- `test/plugins/*/test-*-hooks.sh` - Plugin-specific test suites

**What the tests verify**:
- Hook exit codes (0 for success, 2 for blocking)
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

- Marketplace version in `.claude-plugin/marketplace.json`
- Plugin version in `plugins/core/.claude-plugin/plugin.json`
- Keep versions in sync when releasing updates

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
