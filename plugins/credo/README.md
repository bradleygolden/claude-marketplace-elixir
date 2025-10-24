# credo

Credo static code analysis plugin for Claude Code.

## Installation

```bash
claude
/plugin install credo@elixir
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- Credo installed in your project (add `{:credo, "~> 1.7", only: [:dev, :test], runtime: false}` to mix.exs)
- Run from an Elixir project directory (with mix.exs)

## Features

### Automatic Hooks

**PostToolUse - After file edits:**
- ✅ **Code analysis** - Automatically runs `mix credo` on edited .ex/.exs files
- ✅ **Context-aware feedback** - Claude sees the output and can address issues automatically

**PreToolUse - Before git commits:**
- ✅ **Pre-commit check** - Runs `mix credo --strict` before any `git commit` and blocks if violations found

## Hooks Behavior

### Code Analysis (Non-blocking)
```bash
mix credo {{file_path}}
```
- Runs automatically after editing .ex or .exs files
- Non-blocking - informs Claude without stopping workflow
- Output truncated to 30 lines to avoid overwhelming context

### Pre-commit Check (Blocking)
```bash
mix credo --strict
```
- Runs before any `git commit` command
- **Blocks commits** when Credo finds violations (similar to compile errors)
- Sends violations to Claude via stderr for review
- Output truncated to 30 lines if needed
- Exits silently for non-Elixir projects
- **Pattern**: Matches core plugin's PreToolUse blocking pattern (`exit 2` + stderr)
- **Context Detection**: Automatically finds Mix project root by traversing upward from current directory
