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

**PostToolUse - After reading files:**
- ✅ **Documentation recommendation on read** - Detects dependency usage in files and suggests documentation lookup

**PreToolUse - Before git commits:**
- ✅ **Pre-commit validation** - Ensures code is formatted, compiles, and has no unused deps before committing

**UserPromptSubmit - On user input:**
- ✅ **Documentation recommendation** - Suggests using documentation skills when prompt mentions project dependencies

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

**usage-rules** - Package best practices and coding conventions search:
- 🔍 **Local deps search** - Searches installed packages in `deps/` for usage-rules.md files
- 💾 **Fetched cache** - Checks previously fetched rules in `.usage-rules/`
- ⬇️ **Progressive fetch** - Automatically fetches missing usage rules when needed
- 🎯 **Context-aware** - Extracts relevant sections based on coding context (querying, errors, etc.)
- 📝 **Pattern examples** - Shows good/bad code examples from package maintainers
- 🤝 **Integrates with hex-docs-search** - Combine for comprehensive "best practices + API" guidance
- 🚀 **Offline-capable** - Once fetched, usage rules available without network access

See [skills/usage-rules/SKILL.md](skills/usage-rules/SKILL.md) for details.

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

### Documentation Recommendation (Non-blocking)
- Runs when user submits a prompt
- Detects when prompt mentions project dependencies (e.g., "Ash", "Ecto", "Phoenix")
- Recommends using hex-docs-search or usage-rules skills for documentation lookup
- Uses fuzzy matching to handle case variations and naming conventions
- Caches dependency list in `.hex-docs/deps-cache.txt` for performance
- Cache invalidates when `mix.lock` changes

### Documentation Recommendation on Read (Non-blocking)
- Runs when reading .ex or .exs files
- Detects dependency module references in the file (e.g., `Jason.decode()`, `Ecto.Query.from()`)
- Extracts modules from both aliased (`alias Ecto.Query`) and direct usage (`Jason.decode()`)
- Smart matching: Reports both base and specific dependencies (e.g., `Phoenix.LiveView` → `phoenix, phoenix_live_view`)
- Excludes unrelated dependencies with similar names (e.g., won't report `phoenix_html` when only `Phoenix.LiveView` is used)
- Recommends using hex-docs-search or usage-rules skills for matched dependencies
- Shares dependency cache with UserPromptSubmit hook for efficiency
