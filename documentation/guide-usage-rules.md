# Usage Rules Guide

Your dependencies provide best practices that Claude follows automatically. No more "use idiomatic Elixir" prompts - Claude just knows.

## How It Works

When you install Claude, it syncs usage rules from your dependencies to `CLAUDE.md`:

```bash
mix claude.install
# ✅ Found usage rules for: elixir, otp, phoenix, ecto, ash
# ✅ Synced to CLAUDE.md
```

Claude reads these files and follows the patterns automatically.

## What Gets Synced

Common packages with usage rules:
- **Elixir Core** - Pattern matching, error handling, data structures  
- **OTP** - GenServer, Task, fault tolerance patterns
- **Phoenix** - Controllers, routers, endpoint best practices
- **LiveView** - Component, event handling, state management
- **Ecto** - Schema, changeset, query patterns
- **Ash** - Resource, action, calculation patterns

## Directory-Specific Rules

Different parts of your project get different rules:

```elixir
# .claude.exs (Phoenix plugin does this automatically)
%{
  nested_memories: %{
    "test" => ["usage_rules:elixir", "usage_rules:otp"],
    "lib/my_app" => ["usage_rules:elixir", "usage_rules:otp", "phoenix:ecto"],
    "lib/my_app_web" => ["usage_rules:elixir", "usage_rules:otp", "phoenix:phoenix", "phoenix:liveview"]
  }
}
```

This creates `CLAUDE.md` files in each directory with relevant rules.

## Manual Commands

Check what's available:
```bash
mix usage_rules.sync --list
```

Sync specific rules:
```bash
mix usage_rules.sync phoenix
```

Re-sync everything:
```bash
mix usage_rules.sync
```

## Example: Phoenix Project

Before usage rules:
```
> Create a LiveView component for user profiles
# Claude might write non-idiomatic Phoenix code
```

After usage rules:
```
> Create a LiveView component for user profiles  
# Claude follows Phoenix conventions:
# - Uses proper function components
# - Includes correct LiveView imports
# - Follows Phoenix naming patterns
# - Uses idiomatic event handling
```

## Slash Commands

Manage nested memories easily:

- `/memory:nested-add` - Add rules to directories
- `/memory:nested-list` - See current setup
- `/memory:nested-sync` - Regenerate CLAUDE.md files

## Need More?

- **Quick reference:** [Usage Rules Cheatsheet](../cheatsheets/usage-rules.cheatmd)
- **Package docs:** [Usage Rules Package](https://hexdocs.pm/usage_rules)