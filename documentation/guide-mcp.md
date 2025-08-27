# MCP Servers

Claude automatically extends Claude Code's capabilities with MCP servers that provide external tools and services.

## Quick Start

For Phoenix projects, Claude automatically sets up Tidewave MCP server when you run:

```bash
mix claude.install
```

## Configuration

Define MCP servers in `.claude.exs`:

```elixir
%{
  mcp_servers: [:tidewave]  # Auto-configured for Phoenix
}
```

Custom port configuration:

```elixir
%{
  mcp_servers: [
    {:tidewave, [port: 5000]}
  ]
}
```

Disable without removing:

```elixir
%{
  mcp_servers: [
    {:tidewave, [enabled?: false]}
  ]
}
```

After changes, run `mix claude.install` to update `.mcp.json`.

## How It Works

1. MCP servers defined in `.claude.exs`
2. Generated to `.mcp.json` by `mix claude.install`  
3. Tools available as `mcp__<server>__<tool>` in Claude Code

## Available Servers

| Server | Purpose | Auto-Configured |
|--------|---------|----------------|
| **Tidewave** | Phoenix development tools | Yes (Phoenix projects) |

## Troubleshooting

**Server not starting?**
- Run `mix claude.install` to generate `.mcp.json`
- Check server binary is installed

**Tools not appearing?**
- Verify server enabled in `.claude.exs`
