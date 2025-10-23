# core

Essential Elixir development support plugin for Claude Code.

## Installation

### From GitHub
```bash
claude
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install core@elixir
```

### Local Development
```bash
claude
/plugin marketplace add /path/to/claude-marketplace-elixir
/plugin install core@elixir
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- Run from an Elixir project directory (with mix.exs)

## Features

### Automatic Hooks

**PostToolUse - After file edits:**
- ✅ **Auto-format** - Automatically runs `mix format` on edited .ex/.exs files
- ✅ **Compile check** - Runs `mix compile --warnings-as-errors` to catch errors immediately

**PreToolUse - Before git commits:**
- ✅ **Pre-commit validation** - Ensures code is formatted, compiles, and has no unused deps before committing

## Hooks Behavior

### Auto-format (Non-blocking)
```bash
mix format {{file_path}}
```
- Runs automatically after editing .ex or .exs files
- Non-blocking - just formats and continues
- Fast - only formats the changed file

### Compile Check (Blocking on errors)
```bash
mix compile --warnings-as-errors
```
- Runs after editing .ex or .exs files
- Blocks on compilation errors - Claude must fix before continuing
- Output truncated to 50 lines to avoid overwhelming context

### Pre-commit Validation (Blocking)
```bash
mix format --check-formatted &&
mix compile --warnings-as-errors &&
mix deps.unlock --check-unused
```
- Runs before any `git commit` command (including `git add && git commit`)
- Blocks commit if any check fails
- Three checks:
  1. All files are formatted
  2. Code compiles without warnings
  3. No unused dependencies
