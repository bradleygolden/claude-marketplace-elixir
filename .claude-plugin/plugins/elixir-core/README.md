# elixir-core

Essential Elixir development support plugin for Claude Code.

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

## Installation

### From GitHub
```bash
claude
/plugin marketplace add github:bradleygolden/claude
/plugin install elixir-core@claude
```

### Local Development
```bash
claude
/plugin marketplace add /path/to/claude
/plugin install elixir-core@claude
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- Run from an Elixir project directory (with mix.exs)

## What This Plugin Does NOT Include

This is the **core** plugin - it only provides hooks for basic Elixir development.

For framework-specific support, install additional plugins:
- `elixir-phoenix` - Phoenix framework support
- `elixir-ash` - Ash framework support
- `elixir-ecto` - Ecto database toolkit support

## Design Philosophy

**Minimal and Fast:**
- Only essential hooks that benefit all Elixir projects
- No framework-specific logic
- Fast execution - hooks only run on relevant files

**Non-intrusive:**
- Auto-format just fixes issues silently
- Compile errors block but don't spam output
- Pre-commit validation only runs on commits

**Universal:**
- Works with any Elixir project
- No configuration needed
- Compatible with all Elixir versions

## Troubleshooting

**Hook not running:**
- Ensure you're editing .ex or .exs files
- Check that mix is available: `mix --version`
- Verify you're in an Elixir project directory

**Compilation errors blocking edits:**
- This is intentional! Fix the compilation errors
- Claude will see the error output and help fix it

**Pre-commit validation failing:**
- Run `mix format` to format all files
- Fix compilation warnings/errors
- Run `mix deps.unlock --check-unused` and remove unused deps

## Future Plans

Future versions may include:
- Commands (/elixir-test, /elixir-compile, /elixir-format)
- Skills (Elixir patterns, OTP patterns, testing patterns)
- Agents (specialized Elixir assistants)

For now, hooks provide the essential automation for Elixir development.
