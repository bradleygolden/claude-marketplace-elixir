# Claude Hooks

Claude provides a modern atom-based hook system that integrates with Claude Code to ensure your Elixir code is production-ready. The hooks use sensible defaults and can be configured with simple atom shortcuts.

> 📋 **Quick Reference**: See the [Hooks Cheatsheet](../cheatsheets/hooks.cheatmd) for a concise reference of configuration options and patterns.

## Documentation

For complete documentation on Claude Code's hook system:
- [Official Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks) - Complete API reference
- [Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks-guide) - Getting started with examples

For a quick reference of all hook configurations, see the [Hook Configuration Cheatsheet](../cheatsheets/hooks.cheatmd).

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

## Hook Events

Different hook events run at different times:

- **`pre_tool_use`** - Before tool execution (can block tools)
- **`post_tool_use`** - After tool execution completes successfully
- **`user_prompt_submit`** - Before processing user prompts (can add context or block)
- **`notification`** - When Claude needs permission or input is idle
- **`stop`** - When Claude Code finishes responding (main agent)
- **`subagent_stop`** - When a sub-agent finishes responding
- **`pre_compact`** - Before context compaction (manual or automatic)
- **`session_start`** - When Claude Code starts or resumes a session

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

## Request a New Hook

Have an idea for a new standardized hook that would be useful for Elixir development? We'd love to hear from you!

[Request a new hook →](https://github.com/bradleygolden/claude/issues/new?title=Hook%20Request:%20[Name]&body=**Hook%20Name:**%20%0A**Mix%20Task%20or%20Command:**%20%0A**Use%20Case:**%20%0A**Which%20Events:**%20%0A%0APlease%20describe%20what%20this%20hook%20would%20do%20and%20why%20it%20would%20be%20useful%20for%20Elixir%20developers.)

Popular requests might be added as default hooks in future releases!

## Troubleshooting

**Hooks not running?**
- Check `.claude/settings.json` exists and contains hook configuration
- Verify `.claude.exs` has the correct hook definitions
- Run `mix claude.install` to regenerate hook configuration
- Use Claude Code's `/hooks` command to verify hooks are registered

**Compilation/format errors not showing?**
- Ensure hooks are defined for the right events (`post_tool_use`, `stop`, etc.)
- Check that the `:compile` and `:format` atoms are included
- Verify Mix is available in your PATH

**Need help?**
- 💬 [GitHub Discussions](https://github.com/bradleygolden/claude/discussions)
- 🐛 [Issue Tracker](https://github.com/bradleygolden/claude/issues)

## Learn More

For more details on hook events, configuration, and advanced usage, see the [official documentation](https://docs.anthropic.com/en/docs/claude-code/hooks).
