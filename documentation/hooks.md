# Claude Hooks

Claude automatically installs several hooks to help ensure your Elixir code is production-ready. This library provides a batteries-included integration with Claude Code's hook system.

## Documentation

For complete documentation on Claude Code's hook system:
- [Official Hooks Reference](https://docs.anthropic.com/en/docs/claude-code/hooks) - Complete API reference
- [Hooks Guide](https://docs.anthropic.com/en/docs/claude-code/hooks-guide) - Getting started with examples

## What Claude Installs

When you run `mix igniter.install claude`, it automatically sets up:

1. **Format checking** - Alerts when Elixir files need formatting
2. **Compilation checking** - Catches errors and warnings immediately  
3. **Pre-commit validation** - Ensures clean code before commits

## Configuration

Claude's hooks are configured in `.claude.exs`. You can enable optional built-in hooks:

```elixir
%{
  hooks: [
    # Optional: Enable related files suggestions
    Claude.Hooks.PostToolUse.RelatedFiles
  ]
}
```

## Available Hooks

Claude provides several built-in hooks that cover common Elixir development needs:

### Included by Default
- **ElixirFormatter** - Checks if .ex/.exs files need formatting after edits
- **CompilationChecker** - Validates compilation after file changes
- **PreCommitCheck** - Ensures code quality before git commits

### Optional Hooks
- **RelatedFiles** - Suggests updating test files when lib files change (and vice versa)

To enable optional hooks, add them to your `.claude.exs` configuration as shown above.

## Important Notes

- **Format checking only**: The formatter hook only checks if files need formatting - it doesn't automatically format. This gives you control over when formatting happens.
- **JSON-only output**: All hooks now output JSON exclusively for consistent communication with Claude Code.
- **Feedback to Claude**: Hooks communicate with Claude through structured JSON responses, allowing Claude to automatically see and respond to issues.
- **Performance**: Hooks run with a default 60-second timeout, configurable per hook.

For more details on hook events, configuration, and advanced usage, see the [official documentation](https://docs.anthropic.com/en/docs/claude-code/hooks).