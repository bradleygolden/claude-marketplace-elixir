# elixir

Comprehensive Elixir development support for Claude Code. One plugin, all the tools.

## Installation

```bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install elixir@elixir
```

## Features

This plugin automatically detects your project dependencies and enables relevant checks. No configuration required.

### Post-Edit Hooks (After File Changes)

When you edit `.ex` or `.exs` files:

| Check | When | Behavior |
|-------|------|----------|
| **Format** | Always | Auto-formats the file |
| **Compile** | Always | Checks for compilation errors |
| **Credo** | If `{:credo, ...}` in mix.exs | Reports code quality issues |
| **Ash Codegen** | If `{:ash, ...}` in mix.exs | Checks if codegen is needed |
| **Sobelow** | If `{:sobelow, ...}` in mix.exs | Reports security findings |

### Pre-Commit Hooks (Before Git Commit)

When you run `git commit`:

| Check | When | Behavior |
|-------|------|----------|
| **Precommit Alias** | If `mix precommit` exists | Defers to your alias, skips other checks |
| **Format** | Always | Blocks if code not formatted |
| **Compile** | Always | Blocks on compilation errors |
| **Unused Deps** | Always | Blocks if unused dependencies |
| **Credo** | If dependency | Blocks on strict mode failures |
| **Ash Codegen** | If dependency | Blocks if codegen needed |
| **Dialyzer** | If `{:dialyxir, ...}` | Blocks on type errors |
| **ExDoc** | If `{:ex_doc, ...}` | Blocks on doc warnings |
| **Tests** | If `test/` exists | Runs `mix test --stale` |
| **Mix Audit** | If `{:mix_audit, ...}` | Blocks on vulnerabilities |
| **Sobelow** | If dependency | Blocks on security issues |

### Skills

**hex-docs-search** - Search Hex package documentation:
- Searches local deps first, then fetches if needed
- Caches documentation for offline access
- Falls back to HexDocs API and web search

**usage-rules** - Find package best practices:
- Searches for usage-rules.md in packages
- Provides coding conventions and patterns
- Shows good/bad code examples

## How It Works

1. **Dependency Detection**: Checks your `mix.exs` for each tool's dependency
2. **Smart Defaults**: Only runs checks relevant to your project
3. **Precommit Deferral**: If you have a `mix precommit` alias, uses that instead
4. **Aggregated Feedback**: Collects all issues and reports them together
5. **Concurrent Execution Protection**: ExDoc uses cross-process locking to prevent race conditions

## Hook Timeouts

| Hook | Timeout | Reason |
|------|---------|--------|
| Post-edit | 30s | Quick checks for immediate feedback |
| Pre-commit | 180s | Comprehensive validation including Dialyzer |

## Requirements

- Elixir and Mix installed
- A Mix project (mix.exs in project root)
- Optional: Individual tool dependencies for specific checks

## Phoenix 1.8+ Projects

If your project has a `mix precommit` alias (standard in Phoenix 1.8+), this plugin will automatically defer to it for pre-commit validation. This lets you customize exactly which checks run.

## Migrating from Individual Plugins

If you previously installed individual plugins (core@elixir, credo@elixir, etc.), you can:

1. Install this combined plugin: `/plugin install elixir@elixir`
2. Uninstall old plugins: `/plugin uninstall core@elixir credo@elixir ...`

The combined plugin includes all functionality from the individual plugins.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## License

MIT
