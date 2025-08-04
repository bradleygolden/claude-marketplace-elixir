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

Claude's hooks are configured in `.claude.exs`. You can add optional hooks or create custom ones:

```elixir
%{
  hooks: [
    # Optional: Enable related files suggestions
    Claude.Hooks.PostToolUse.RelatedFiles,
    
    # Add your custom hooks
    MyApp.Hooks.CustomChecker
  ]
}
```

## Creating Custom Hooks

### Using the Generator

The easiest way to create a new hook is with the generator:

```bash
mix claude.gen.hook MyCustomChecker --event post_tool_use --matcher "Write|Edit" --description "My custom validation hook"
```

See the [Generators Documentation](generators.md#hook-generator) for full details.

### Manual Creation

You can also extend Claude with your own hooks using the `Claude.Hook` macro:

```elixir
defmodule MyApp.Hooks.CustomChecker do
  use Claude.Hook,
    event: :post_tool_use,
    matcher: [:write, :edit],
    description: "My custom validation hook"

  @impl true
  def handle(%Claude.Hooks.Events.PostToolUse.Input{} = input) do
    # Your hook logic here
    # Return :ok, {:block, reason}, {:allow, reason}, or {:deny, reason}
    :ok
  end
end
```

## Important Notes

- **Format checking only**: The formatter hook only checks if files need formatting - it doesn't automatically format. This gives you control over when formatting happens.
- **JSON-only output**: All hooks now output JSON exclusively for consistent communication with Claude Code.
- **Feedback to Claude**: Hooks communicate with Claude through structured JSON responses, allowing Claude to automatically see and respond to issues.
- **Performance**: Hooks run with a default 60-second timeout, configurable per hook.

For more details on hook events, configuration, and advanced usage, see the [official documentation](https://docs.anthropic.com/en/docs/claude-code/hooks).