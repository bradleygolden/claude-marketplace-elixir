# Claude Hooks

Claude provides a modern atom-based hook system that integrates with Claude Code to ensure your Elixir code is production-ready. The hooks use sensible defaults and can be configured with simple atom shortcuts.

## Documentation

For complete documentation on Claude Code's hook system:
- [Official Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks) - Complete API reference
- [Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks-guide) - Getting started with examples

## What Claude Installs

When you run `mix igniter.install claude`, it automatically sets up default hooks:

```elixir
%{
  hooks: %{
    stop: [:compile, :format],
    subagent_stop: [:compile, :format],
    post_tool_use: [:compile, :format],
    # These only run on git commit commands
    pre_tool_use: [:compile, :format, :unused_deps]
  }
}
```

This provides:
1. **Format checking** - Alerts when Elixir files need formatting
2. **Compilation checking** - Catches errors and warnings immediately  
3. **Pre-commit validation** - Ensures clean code before commits

## Available Hook Atoms

Claude provides these atom shortcuts that expand to full hook configurations:

### Available Hooks
- **`:compile`** - Runs `mix compile --warnings-as-errors` with `halt_pipeline?: true` (stops on failure)
- **`:format`** - Runs `mix format --check-formatted` (checks only, doesn't auto-format)
- **`:unused_deps`** - Runs `mix deps.unlock --check-unused` (pre_tool_use on git commits only)
- **`:deps_get`** - Runs `mix deps.get` (session_start on startup only)

## Hook Events

Different hook events run at different times:

- **`stop`** - When Claude Code finishes responding
- **`subagent_stop`** - When a sub-agent finishes responding
- **`post_tool_use`** - After Claude edits/writes files
- **`pre_tool_use`** - Before tool use (e.g., git commits)
- **`session_start`** - When Claude Code starts

## Advanced Configuration

You can mix atom shortcuts with explicit configurations:

```elixir
%{
  hooks: %{
    # Standard hooks
    post_tool_use: [:compile, :format],
    
    # Custom hook with options
    stop: [
      :format,
      {"custom_task", halt_pipeline?: true},
      {"cmd echo 'Done'", blocking?: false}
    ],
    
    # Conditional execution
    pre_tool_use: [
      {"test", when: "Bash", command: ~r/^git push/}
    ]
  }
}
```

### Hook Options

- **`:when`** - Tool/event matcher (atoms, strings, or lists)
- **`:command`** - Additional command pattern for Bash (string or regex)
- **`:halt_pipeline?`** - Stop subsequent hooks on failure (default: false)
- **`:blocking?`** - Treat non-zero exit as blocking error (default: true)
- **`:env`** - Environment variables as a map

## How It Works

1. **Configuration**: Define hooks in `.claude.exs` using atoms, strings, or tuples with options
2. **Installation**: `mix claude.install` creates `.claude/settings.json` with a dispatcher command
3. **Execution**: Claude Code runs `mix claude.hooks.run <event>` passing JSON via stdin
4. **Expansion**: The dispatcher reads `.claude.exs` and expands atoms to full commands
5. **Running**: Commands execute as Mix tasks (default) or shell commands (with "cmd " prefix)
6. **Communication**: Hooks return exit codes only (0 = success, non-zero = failure, no JSON output)

For more details on hook events, configuration, and advanced usage, see the [official documentation](https://docs.anthropic.com/en/docs/claude-code/hooks).