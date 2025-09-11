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
    post_tool_use: [:compile, :format],
    # These only run on git commit commands
    pre_tool_use: [:compile, :format, :unused_deps]
  }
}
```

This provides:
1. **Immediate validation** - Formats code and checks compilation after file edits
2. **Pre-commit validation** - Ensures clean code before commits, including unused dependency checks

## Available Hook Atoms

Claude provides these atom shortcuts that expand to full hook configurations:

### Available Hooks
- **`:compile`** - Runs `mix compile --warnings-as-errors` with `halt_pipeline?: true` (stops on failure)
  - For `stop`/`subagent_stop`: Uses `blocking?: false` to prevent infinite loops
- **`:format`** - Runs `mix format` to automatically format code
  - For `stop`/`subagent_stop`: Uses `blocking?: false` to prevent infinite loops
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

## Best Practices

### Choosing the Right Hook Event

- **`post_tool_use`** - Use for immediate validation after file edits (formatting, compilation)
- **`pre_tool_use`** - Use for validation before critical operations like git commits
- **`stop`/`subagent_stop`** - Use sparingly for simple operations that rarely fail (see Advanced section)

### What Makes a Good Hook

✅ **Good hook operations:**
- Auto-formatting with `mix format`
- Compilation with `mix compile --warnings-as-errors`
- Simple logging or metrics collection
- Read-only operations that provide context

❌ **Avoid in hooks:**
- Running tests (use explicit commands instead)
- Operations that frequently fail for legitimate reasons
- Complex multi-step processes
- Operations that might trigger additional work

## Advanced Configuration

You can mix atom shortcuts with explicit configurations:

```elixir
%{
  hooks: %{
    # Standard hooks - recommended default
    post_tool_use: [:compile, :format],
    pre_tool_use: [:compile, :format, :unused_deps],

    # Conditional execution
    pre_tool_use: [
      {"test", when: "Bash", command: ~r/^git push/}
    ],
    
    # Control output verbosity (rarely needed)
    post_tool_use: [
      {:compile, output: :full},  # WARNING: Can cause context overflow
      :format                     # Default :none - recommended
    ]
  }
}
```

### Stop and Subagent Stop Hooks (Advanced)

⚠️ **Stop hooks are not included in default configuration due to the risk of notification stacking.**

Stop hooks run when Claude finishes responding. Use them ONLY for:
- Simple logging and metrics collection
- Notifications that rarely fail
- Cleanup operations with high success rates

**DO NOT use stop hooks for:**
- Running tests (use pre_tool_use for commits instead)
- Compilation checks (use post_tool_use after edits)
- Any validation that might legitimately fail
- Operations that could trigger additional work

Even with `blocking?: false`, failed stop hooks generate persistent notifications in Claude Code that can stack up and become disruptive.

```elixir
%{
  hooks: %{
    # Standard hooks (recommended)
    post_tool_use: [:compile, :format],
    pre_tool_use: [:compile, :format, :unused_deps],
    
    # Stop hooks - opt-in only, use carefully
    stop: [
      {"cmd echo 'Session complete'", blocking?: false},  # Simple notification
      {"log_metrics", blocking?: false}                   # Logging only
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
- **`:output`** - Control output verbosity (default: `:none`)
  - `:none` - Only show pipeline summary on failures (prevents context overflow) **[Recommended]**
  - `:full` - Show complete hook output plus pipeline summary (use sparingly - can cause context issues)

## Hook Event Reporting (Experimental)

Claude supports sending hook events to external systems for monitoring and integration.

### Webhook Reporter

**Note: This feature is experimental and the API may change in future releases.**

Send hook events to HTTP endpoints:

```elixir
%{
  reporters: [
    {:webhook,
      url: "https://example.com/webhook",
      headers: %{"Authorization" => "Bearer token"},
      timeout: 5000,
      retry_count: 3
    }
  ]
}
```

The webhook reporter sends the raw Claude Code hook event data as JSON, including:
- Event type and timestamp
- Tool information (for tool-related events)
- Session and project context

## How It Works

1. **Configuration**: Define hooks in `.claude.exs` using atoms, strings, or tuples with options
2. **Installation**: `mix claude.install` creates `.claude/settings.json` with a dispatcher command
3. **Execution**: Claude Code runs `mix claude.hooks.run <event>` passing JSON via stdin
4. **Expansion**: The dispatcher reads `.claude.exs` and expands atoms to full commands
5. **Running**: Commands execute as Mix tasks (default) or shell commands (with "cmd " prefix)
6. **Communication**: Hooks return exit codes only (0 = success, non-zero = failure, no JSON output)
7. **Reporting**: Events are dispatched to configured reporters for external integration

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
