# dialyzer

Dialyzer static type analysis plugin for Claude Code.

## Installation

```bash
claude
/plugin install dialyzer@elixir
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- Dialyzer installed (included with Erlang/OTP)
- Dialyxir installed in your project (add `{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}` to mix.exs)
- Run from an Elixir project directory (with mix.exs)
- Initial PLT (Persistent Lookup Table) built with `mix dialyzer --plt`

## Features

### Automatic Hooks

**PreToolUse - Before git commits:**
- ✅ **Pre-commit check** - Runs `mix dialyzer` before any `git commit` and blocks if type errors found

## Hooks Behavior

### Pre-commit Check (Blocking)
```bash
mix dialyzer
```
- Runs before any `git commit` command
- **Blocks commits** when Dialyzer finds type errors
- Sends violations to Claude via JSON permissionDecision for review
- Output truncated to 30 lines if needed
- Exits silently for non-Elixir projects
- **Pattern**: Uses JSON permissionDecision with deny status to block commits
- **Context Detection**: Automatically finds Mix project root by traversing upward from current directory
- **Timeout**: 120 seconds (Dialyzer can take longer than other checks)
- **Note**: Skips if project has a `precommit` alias (defers to precommit plugin)

## Why Pre-commit Only?

Unlike Credo or compilation checks, Dialyzer is intentionally only run on commit because:
- **Performance**: Dialyzer analysis can take significant time, especially on first run
- **Scope**: Dialyzer analyzes the entire codebase, not just individual files
- **Intent**: Type safety checks are best validated when you're ready to commit, not on every edit

## Setup

Before using this plugin, ensure you've built the PLT:

```bash
mix dialyzer --plt
```

This is a one-time setup (unless you upgrade Erlang/Elixir or add new dependencies).
