# MCP Servers

Claude integrates with Model Context Protocol (MCP) servers to extend Claude Code's capabilities with external tools and services.

> 📋 **Quick Reference**: See the [MCP Cheatsheet](../cheatsheets/mcp.cheatmd) for a concise reference of configuration options.

## What is MCP?

Model Context Protocol (MCP) is an open standard that enables secure, controlled interactions between AI assistants and external systems. MCP servers provide tools that Claude Code can use to interact with databases, APIs, and other services.

For complete documentation, see the [official Claude Code MCP guide](https://docs.anthropic.com/en/docs/claude-code/mcp).

## Tidewave for Phoenix Projects

Claude automatically configures [Tidewave](https://tidewave.ai/) for Phoenix projects. Tidewave is an MCP server that provides Phoenix-specific development tools.

### Automatic Setup

When you run `mix claude.install` in a Phoenix project, Claude automatically:

1. Detects Phoenix is installed
2. The `Claude.Plugins.Phoenix` plugin automatically adds Tidewave to your configuration
3. Generates `.mcp.json` with the proper server configuration
4. Enables the MCP server in Claude Code

The Phoenix plugin handles this configuration seamlessly - see the [Plugin System Guide](guide-plugins.md) for more details on how plugins auto-configure your project.

### Manual Configuration

You can also manually configure Tidewave or other MCP servers in `.claude.exs`:

```elixir
%{
  mcp_servers: [:tidewave]
}
```

Or with custom port configuration:

```elixir
%{
  mcp_servers: [
    {:tidewave, [port: 5000]}
  ]
}
```

To disable a server without removing it:

```elixir
%{
  mcp_servers: [
    {:tidewave, [enabled?: false]}
  ]
}
```

After updating `.claude.exs`, run `mix claude.install` to sync the configuration to `.mcp.json`.

## How MCP Servers Work with Claude

1. **Configuration**: MCP servers are defined in `.mcp.json` (generated from `.claude.exs`)
2. **Startup**: Claude Code starts configured MCP servers when you begin a session
3. **Tool Access**: MCP server tools appear as `mcp__<server>__<tool>` in Claude Code
4. **Usage**: Claude can use these tools just like built-in tools

## Available MCP Servers

Currently, Claude supports:

- **Tidewave** - Phoenix development tools (auto-configured for Phoenix projects)

## Request Additional MCP Servers

Want support for additional MCP servers? We'd love to hear from you!

[Request a new MCP server →](https://github.com/bradleygolden/claude/issues/new?title=MCP%20Server%20Request:%20[Server%20Name]&body=**Server%20Name:**%20%0A**Server%20Repository:**%20%0A**Use%20Case:**%20%0A%0APlease%20describe%20why%20this%20MCP%20server%20would%20be%20useful%20for%20Elixir%20development.)

## Troubleshooting

**MCP server not starting?**
- Check `.mcp.json` exists after running `mix claude.install`
- Verify the server binary is installed (e.g., `tidewave` for Phoenix)
- Check Claude Code logs for startup errors

**Tools not appearing?**
- Restart your Claude Code session
- Verify the server is enabled in `.claude.exs`
- Check that `.mcp.json` contains the server configuration

**Need help?**
- 💬 [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

## Learn More

- [Claude Code MCP Documentation](https://docs.anthropic.com/en/docs/claude-code/mcp) - Official guide
- [MCP Specification](https://modelcontextprotocol.io/) - Protocol details
- [Tidewave](https://tidewave.ai/) - Phoenix MCP server
