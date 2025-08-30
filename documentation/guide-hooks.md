# Hooks Guide

Claude hooks automatically check your code quality and prevent issues before they become problems.

## What Are Hooks?

Hooks are commands that run automatically when Claude Code performs actions:
- **After editing files** → Check formatting and compilation
- **Before git commits** → Validate everything is clean
- **When sessions end** → Run cleanup tasks

## Quick Setup

Most users just need these three shortcuts:

```elixir
# .claude.exs
%{
  hooks: %{
    post_tool_use: [:compile, :format],    # Check after edits
    # These only run on git commit commands
    pre_tool_use: [:compile, :format, :unused_deps],  # Validate before commits
    session_end: ["mix myapp.cleanup"]     # Optional cleanup
  }
}
```

Run `mix claude.install` to apply.

This provides:
1. **Immediate validation** - Checks formatting and compilation after file edits
2. **Pre-commit validation** - Ensures clean code before commits, including unused dependency checks

## The Three Magic Shortcuts

| Shortcut | What It Does | When It Runs |
|----------|--------------|--------------|
| `:compile` | Runs `mix compile --warnings-as-errors` | After file edits, before commits |
| `:format` | Runs `mix format --check-formatted` | After file edits, before commits |
| `:unused_deps` | Checks for unused dependencies | Before git commits only |

## Hook Events

Different events run at different times:

- **`post_tool_use`** - After Claude edits files (immediate feedback)
- **`pre_tool_use`** - Before tools run (can block unsafe operations)
- **`stop`** - When Claude finishes responding
- **`session_end`** - When your Claude session ends (cleanup, logging, etc.)

## Best Practices

### Choosing the Right Hook Event

- **`post_tool_use`** - Use for immediate validation after file edits (formatting, compilation)
- **`pre_tool_use`** - Use for validation before critical operations like git commits
- **`stop`/`subagent_stop`** - Use sparingly for simple operations that rarely fail (see Advanced section)

### What Makes a Good Hook

✅ **Good hook operations:**
- Format checking with `mix format --check-formatted`
- Compilation with `mix compile --warnings-as-errors`
- Simple logging or metrics collection
- Read-only operations that provide context

❌ **Avoid in hooks:**
- Running tests (use explicit commands instead)
- Operations that frequently fail for legitimate reasons
- Complex multi-step processes
- Operations that might trigger additional work

## Common Patterns

**Basic Quality Checks:**
```elixir
%{
  hooks: %{
    post_tool_use: [:compile, :format]  # Fast feedback after edits
  }
}
```

**Pre-commit Protection:**
```elixir
%{
  hooks: %{
    pre_tool_use: [:compile, :format, :unused_deps]  # Block bad commits
  }
}
```

**Advanced Configuration:**
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
    ],

    # Session cleanup
    session_end: [
      "mix myapp.cleanup",
      "mix myapp.log_session_stats"
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

## Custom Commands

Add your own commands alongside the shortcuts:

```elixir
%{
  hooks: %{
    post_tool_use: [
      :compile,
      :format,
      {"credo suggest", blocking?: false}  # Non-blocking suggestion
    ],
    pre_tool_use: [
      {"mix test --failed", when: "Bash", command: ~r/^git commit/}
    ]
  }
}
```

## Event Reporting

Track what happens with reporters:

**Webhook (real-time):**
```elixir
%{
  reporters: [{:webhook, url: "https://api.example.com/claude-events"}],
  hooks: %{
    post_tool_use: [:compile, :format]
  }
}
```

**File logging:**
```elixir
%{
  reporters: [{:jsonl, file: "claude-events.jsonl"}],
  hooks: %{
    session_end: ["mix myapp.cleanup"]
  }
}
```

## How It Works

1. **You configure hooks** in `.claude.exs`
2. **Claude Code runs your hooks** automatically
3. **You get immediate feedback** when issues are found
4. **Claude can fix problems** based on the feedback

No manual work - it just happens.

## Need More?

- **Quick reference:** [Hooks Cheatsheet](../cheatsheets/hooks.cheatmd)
- **Plugin integration:** [Plugin Guide](guide-plugins.md)
- **Official docs:** [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks)