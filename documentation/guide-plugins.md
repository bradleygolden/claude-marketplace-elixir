# Plugin System Guide

Claude's plugin system automatically configures your project with smart defaults. Most users just need the built-in plugins.

## Quick Start

Add plugins to your `.claude.exs`:

```elixir
%{
  plugins: [
    Claude.Plugins.Base,     # Standard hooks (always include)
    Claude.Plugins.Phoenix   # Auto-detects Phoenix projects
  ]
}
```

Run `mix claude.install` to apply changes.

## Built-in Plugins

| Plugin | Auto-Activates | What It Does |
|--------|----------------|--------------|
| **Base** | Always | Adds format/compile checks, pre-commit validation |
| **ClaudeCode** | Always | Includes Claude Code documentation and Meta Agent |
| **Phoenix** | When `:phoenix` dependency | Sets up Tidewave MCP, LiveView/Ecto rules, DaisyUI docs |
| **Webhook** | Manual | Sends hook events to HTTP endpoints |
| **Logging** | Manual | Logs all hook events to JSONL files |

## Phoenix Magic ✨

For Phoenix projects, the Phoenix plugin automatically sets up:
- **Tidewave MCP server** for Phoenix development tools
- **Directory-specific rules** for `lib/app/`, `lib/app_web/`, and `test/`
- **Smart detection** of LiveView, Ecto, and other Phoenix deps
- **DaisyUI component docs** for UI development

Just add `Claude.Plugins.Phoenix` and it handles everything.

## Plugin Options

Customize plugins with options:

```elixir
%{
  plugins: [
    Claude.Plugins.Base,
    {Claude.Plugins.Phoenix, include_daisyui?: false, port: 4001},
    {Claude.Plugins.Webhook, url: "https://api.example.com/hooks"}
  ]
}
```

## Configuration Merging

Plugins work together seamlessly:

```elixir
%{
  plugins: [
    Claude.Plugins.Base,     # Provides hooks
    Claude.Plugins.Phoenix,  # Adds MCP servers + memories
    Claude.Plugins.Logging   # Adds event logging
  ],
  
  # Your custom additions (plugins take precedence)
  hooks: %{
    session_end: ["mix myapp.cleanup"]
  }
}
```

## Common Combinations

**Phoenix Development:**
```elixir
%{
  plugins: [Claude.Plugins.Base, Claude.Plugins.Phoenix]
}
```

**With Event Monitoring:**
```elixir
%{
  plugins: [Claude.Plugins.Base, Claude.Plugins.Webhook]
}
```

**Full Stack:**
```elixir
%{
  plugins: [
    Claude.Plugins.Base,
    Claude.Plugins.Phoenix,
    Claude.Plugins.Logging
  ]
}
```

## Creating Custom Plugins

Only create custom plugins if the built-ins don't meet your needs.

Basic plugin structure:

```elixir
defmodule MyApp.CustomPlugin do
  @behaviour Claude.Plugin
  
  def config(_opts) do
    %{
      hooks: %{
        stop: ["mix myapp.validate"]
      },
      mcp_servers: [myserver: []]
    }
  end
end
```

Use it:

```elixir
%{
  plugins: [Claude.Plugins.Base, MyApp.CustomPlugin]
}
```

## Need More?

- **Hook details:** [Hooks Guide](guide-hooks.md)
- **Quick reference:** [Plugin Cheatsheet](../cheatsheets/plugins.cheatmd)
- **MCP servers:** [MCP Guide](guide-mcp.md)