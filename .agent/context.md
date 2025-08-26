# Important Context

## Project Overview
This is an Elixir library called "Claude" that provides batteries-included Claude Code integration for Elixir projects. Working on Phoenix plugin integration and port customization features.

## Key Architecture
- **Plugins**: Modular configuration system where plugins provide configs that get merged
- **Installer**: `mix claude.install` task that processes configs and sets up projects  
- **Config Processing**: Two functions:
  - `read_and_eval_claude_exs` - reads raw config file
  - `read_config_with_plugins` - processes plugins and merges configs

## Current Problem Analysis
The installer has this flow:
1. Read original config with `read_and_eval_claude_exs` 
2. Read processed config with `read_config_with_plugins` (includes plugin data)
3. Check if Tidewave already configured using processed config
4. If not configured, add `:tidewave` to original config and save

But Phoenix plugin provides: `%{mcp_servers: [tidewave: [port: "${PORT:-8080}"]]}`
So processed config should have this, and `tidewave_already_configured?([tidewave: [port: "${PORT:-8080}"]])` should return `true`.

## Investigation Needed
Why is the installer still adding Tidewave when plugin already provides it? Either:
1. `tidewave_already_configured?` is not working correctly
2. The plugin config is not being merged properly
3. There's a logic error in the installer flow

## Testing Strategy
- Individual Phoenix plugin tests all pass
- Integration tests mostly pass except new port customization test
- Need to debug the specific interaction between plugin and installer