# Phoenix Plugin for Claude Code

This plugin provides [Tidewave](https://tidewave.ai) MCP server integration for Phoenix framework development in Claude Code, enabling runtime intelligence and Phoenix-specific tooling.

## Overview

Tidewave is a coding agent for full-stack Phoenix development that provides:
- Runtime intelligence for Phoenix applications
- Database to UI integration
- LiveView, Ecto, and Phoenix-specific development tools via MCP
- Real-time insights into your running Phoenix application

This plugin configures the Tidewave MCP server to work seamlessly with Claude Code.

## Requirements

### Phoenix Application Setup

Your Phoenix application needs to have Tidewave installed and configured:

1. Add Tidewave to your Phoenix app's dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tidewave, "~> 0.5", only: :dev}
    # ... other deps
  ]
end
```

2. Run `mix deps.get`

3. Install Tidewave in your Phoenix app using Igniter (recommended):

```bash
mix archive.install hex igniter_new
mix igniter.install tidewave
```

**OR** manually add the plug to your `lib/my_app_web/endpoint.ex`:

```elixir
# Add this ABOVE the `if code_reloading?` block
plug Tidewave.Plug
```

4. Start your Phoenix server:

```bash
mix phx.server
```

By default, Tidewave runs on port 4000. If your Phoenix app uses a different port, set the `PORT` environment variable:

```bash
PORT=4001 mix phx.server
```

## Installation

### Step 1: Install the Core Plugin (if not already installed)

```
/plugin install core@elixir
```

The core plugin provides essential Elixir development hooks (auto-formatting, compile checks).

### Step 2: Install the Phoenix Plugin

```
/plugin install phoenix@elixir
```

### Step 3: Configure the Tidewave MCP Server

After installing the plugin, configure the MCP server connection:

```bash
claude mcp add --transport http tidewave http://localhost:${PORT-4000}/tidewave/mcp
```

This command:
- Adds a Tidewave MCP server named "tidewave"
- Uses HTTP transport (SSE - Server-Sent Events)
- Connects to `http://localhost:4000/tidewave/mcp` by default
- Uses the `PORT` environment variable if set, otherwise defaults to port 4000

## Verification

To verify the MCP server is connected and working:

1. Ensure your Phoenix server is running:
   ```bash
   mix phx.server
   ```

2. In Claude Code, check available MCP servers:
   ```
   /mcp
   ```

3. You should see "tidewave" listed as a connected MCP server.

4. The Tidewave MCP server provides Phoenix-specific tools that Claude Code can use automatically during development.

## Features

### Tidewave MCP Server Tools

Once connected, Claude Code can leverage Tidewave's runtime intelligence:

- **Schema Inspection**: Query your Ecto schemas and database structure
- **Route Information**: Inspect Phoenix routes and endpoints
- **LiveView Helpers**: Tools for working with Phoenix LiveView
- **Database Queries**: Execute and analyze database operations
- **Runtime Insights**: Access information about your running Phoenix application

These tools are automatically available to Claude Code through the MCP protocol - no manual invocation needed.

## Configuration

### Custom Ports

If your Phoenix application runs on a non-standard port:

1. Set the `PORT` environment variable when starting your Phoenix server:
   ```bash
   PORT=4001 mix phx.server
   ```

2. Update the MCP server configuration:
   ```bash
   claude mcp add --transport http tidewave http://localhost:4001/tidewave/mcp
   ```

### Remote Access

By default, Tidewave only accepts connections from localhost. If you need to access it from a different machine, configure `allow_remote_access` in your Phoenix app's Tidewave settings.

## Troubleshooting

### MCP Server Not Connecting

1. Verify your Phoenix server is running:
   ```bash
   lsof -i :4000
   ```

2. Check that Tidewave is installed in your Phoenix app:
   ```bash
   mix hex.info tidewave
   ```

3. Test the Tidewave endpoint directly:
   ```bash
   curl http://localhost:4000/tidewave/mcp
   ```

### Using with STDIO-only Editors

If your editor only supports STDIO MCP servers, use the [mcp_proxy_elixir](https://github.com/tidewave-ai/mcp_proxy_elixir) which provides automatic reconnects when you restart your dev server.

## Resources

- [Tidewave Documentation](https://hexdocs.pm/tidewave)
- [Tidewave GitHub](https://github.com/tidewave-ai/tidewave_phoenix)
- [Claude Code MCP Guide](https://docs.claude.com/en/docs/claude-code/mcp)
- [Model Context Protocol (MCP) Spec](https://modelcontextprotocol.io)

## License

MIT - See LICENSE file in the repository root.
