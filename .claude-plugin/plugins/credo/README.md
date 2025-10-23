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
- Automatically runs `mix credo` on edited .ex/.exs files to check code quality

**PreToolUse - Before git commits:**
- Runs `mix credo --strict` to ensure code passes all quality checks before committing

## Hooks Behavior

### Credo Check (Non-blocking after edits)
```bash
mix credo {{file_path}}
```
- Runs automatically after editing .ex or .exs files
- Non-blocking - provides feedback but allows work to continue
- Fast - only analyzes the changed file
- Output truncated to 50 lines to avoid overwhelming context

### Pre-commit Credo Validation (Non-blocking suggestions)
```bash
mix credo --strict
```
- Runs before any `git commit` command (including `git add && git commit`)
- Provides suggestions without blocking the commit
- Uses strict mode for comprehensive checks
- Output truncated to 50 lines to avoid overwhelming context
- Helps ensure code quality but allows commits to proceed
