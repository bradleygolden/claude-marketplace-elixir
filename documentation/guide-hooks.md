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
    pre_tool_use: [:compile, :format, :unused_deps],  # Validate before commits
    session_end: ["mix myapp.cleanup"]     # Optional cleanup
  }
}
```

Run `mix claude.install` to apply.

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

**With Session Cleanup:**
```elixir
%{
  hooks: %{
    post_tool_use: [:compile, :format],
    session_end: [
      "mix myapp.cleanup",
      "mix myapp.log_session_stats"
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