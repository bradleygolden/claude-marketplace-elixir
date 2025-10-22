# Claude Marketplace

This directory defines the Claude Code plugin marketplace for Elixir and BEAM ecosystem tools.

## What is this?

This marketplace provides plugins that extend Claude Code with Elixir-specific capabilities:
- **Skills** - Model-invoked knowledge (Elixir patterns, OTP, testing)
- **Commands** - User-invoked shortcuts (/elixir-test, /elixir-compile)
- **Hooks** - Automatic checks (formatting, compilation, dependencies)

## Available Plugins

### elixir-core
Essential Elixir development support for all Elixir projects.

**Location:** `./elixir-core`

**Includes:**
- Core Elixir language patterns and idioms
- OTP patterns (GenServer, Supervisor, Application)
- Testing patterns with ExUnit
- Commands for common tasks (test, compile, format, deps)
- Hooks for automatic formatting and compilation checks

## Installing Plugins

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

## Adding New Plugins

When adding a new plugin to this marketplace:

1. Create plugin directory (e.g., `elixir-phoenix/`)
2. Add plugin manifest: `elixir-phoenix/.claude-plugin/plugin.json`
3. Update `marketplace.json` to include the new plugin
4. Add plugin components (skills, commands, hooks)

## Marketplace Structure

```
claude/
├── .claude-plugin/
│   ├── marketplace.json    # This file defines the marketplace
│   └── README.md           # This documentation
├── elixir-core/            # Base Elixir plugin
├── elixir-phoenix/         # Phoenix plugin (future)
└── elixir-ash/             # Ash plugin (future)
```

## Documentation

For more information on Claude Code plugins and marketplaces, see:
- [Plugin Documentation](https://docs.anthropic.com/en/docs/claude-code/plugins)
- [Marketplace Documentation](https://docs.anthropic.com/en/docs/claude-code/plugin-marketplaces)
