# Claude

Opinionated Claude Code integration for Elixir projects.

## Our Opinions

1. **Changes that Claude makes should always be production-ready** - Every edit is formatted and checked for compilation errors
2. **Project-scoped by default** - No global state, each project is isolated
3. **Zero configuration** - If you follow Elixir conventions, it just works

## What You Get

A Claude that writes code like an experienced Elixir developer (ideally).

## Why Use This?

Without this library:
- Claude might write unformatted code
- Compilation errors only show up when you manually compile
- You need to manually run `mix format` and `mix compile` after edits
- Claude doesn't know about your project's specific conventions

With this library:
- Every file Claude touches is automatically formatted
- Compilation errors are caught immediately after edits
- Your codebase stays consistent and error-free
- Claude feels like a native Elixir developer

## Installation

Add `claude` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:claude, "~> 0.1.0", only: [:dev, :test], runtime: false}
  ]
end
```

This configuration ensures:
- `only: [:dev, :test]` - The dependency is only available in development and test environments
- `runtime: false` - It won't be included in production releases

## Usage

Install Claude hooks (one time per project):
```bash
mix claude.install
```

That's it. Claude will now automatically:
- Format every Elixir file it edits
- Check for compilation errors after each edit

To uninstall:
```bash
mix claude.uninstall
```

*Note: This only removes configuration added by this library. Your other Claude settings remain untouched.*

## Our Opinionated Defaults

- **Always format & check**: We believe all code should be formatted and compilable
- **Project-local**: No global configs that could conflict between projects
- **Fail silently**: If checks fail, we log but don't interrupt Claude
- **Extensible**: Built on behaviours so you can add your own hooks

## What It Does

### Auto-formatting
Before (what Claude writes):
```elixir
defmodule  MyModule  do
  def hello(  name  )  do
    "Hello, #{ name }!"
  end
end
```

After (automatically formatted):
```elixir
defmodule MyModule do
  def hello(name) do
    "Hello, #{name}!"
  end
end
```

### Compilation Checking
If Claude introduces a compilation error:
```elixir
defmodule MyModule do
  def hello(name) do
    "Hello, #{nam}!"  # Variable 'nam' is undefined
  end
end
```

You'll see immediately in the output:
```
⚠️  Compilation issues detected:
error: undefined variable "nam"
  lib/my_module.ex:3: MyModule.hello/1
```

## Current Features

✅ **Auto-formatting** - Runs `mix format` after Write/Edit/MultiEdit operations
✅ **Compilation checking** - Runs `mix compile --warnings-as-errors` to catch issues immediately

## Coming Soon

🚧 **Test runner** - Run stale tests automatically
🚧 **Credo integration** - Ensure code quality standards
🚧 **Dialyzer support** - Type checking on the fly

## How It Works

This library uses [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to intercept file operations and run Mix tasks in response. When Claude edits an Elixir file, our PostToolUse hooks automatically:

1. Format the file with `mix format`
2. Check for compilation errors with `mix compile --warnings-as-errors`

The hook system is built on Elixir behaviours, making it easy to extend with your own custom hooks.

## Contributing

We welcome contributions! The codebase follows standard Elixir conventions:

- Run tests: `mix test`
- Format code: `mix format`

## License

MIT
