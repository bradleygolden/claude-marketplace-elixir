# core

Essential Elixir development support plugin for Claude Code.

## Installation

```bash
claude
/plugin install core@elixir
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- Run from an Elixir project directory (with mix.exs)
- curl and jq (for hex-docs-search skill)

## Features

### Automatic Hooks

**PostToolUse - After file edits:**
- ✅ **Auto-format** - Automatically runs `mix format` on edited .ex/.exs files
- ✅ **Compile check** - Runs `mix compile --warnings-as-errors` to catch errors immediately

**PreToolUse - Before git commits:**
- ✅ **Pre-commit validation** - Ensures code is formatted, compiles, and has no unused deps before committing

### Skills

**hex-docs-search** - Intelligent Hex package documentation search with progressive fetching:
- 🔍 **Local deps search** - Searches installed packages in `deps/` directory for code and docs
- 💾 **Fetched cache** - Checks previously fetched documentation and source in `.hex-docs/` and `.hex-packages/`
- ⬇️ **Progressive fetch** - Automatically fetches missing documentation or source code locally (with version prompting)
- 📚 **Codebase usage** - Finds real-world usage examples from your project
- 🌐 **HexDocs API** - Queries hex.pm API for official documentation
- 🔎 **Web fallback** - Uses web search when other methods don't provide enough information
- 🚀 **Offline-capable** - Once fetched, documentation and source available without network access

See [skills/hex-docs-search/SKILL.md](skills/hex-docs-search/SKILL.md) for details.

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
