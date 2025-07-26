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
    {:claude, "~> 0.1.0", only: :dev, runtime: false}
  ]
end
```

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

### Supported Hooks

✅ **ElixirFormatter** (Post-tool-use)
- Checks if Elixir files need formatting after edits
- Runs after Write/Edit/MultiEdit operations on `.ex`/`.exs` files
- Shows warnings when formatting is needed
- Non-blocking: provides feedback without interrupting workflow

✅ **CompilationChecker** (Post-tool-use)
- Checks for compilation errors and warnings after edits
- Runs after Write/Edit/MultiEdit operations on `.ex`/`.exs` files
- Uses `mix compile --warnings-as-errors` to ensure code quality
- Non-blocking: displays issues but doesn't prevent operations

✅ **PreCommitCheck** (Pre-tool-use)
- **Blocking hook** that validates code before git commits
- Ensures all files are formatted before committing
- Verifies code compiles without errors or warnings
- Prevents commits if formatting or compilation issues exist

## Coming Soon

🚧 **Test runner** - Run stale tests automatically
🚧 **Credo integration** - Ensure code quality standards
🚧 **Dialyzer support** - Type checking on the fly

## How It Works

This library uses [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to intercept file operations and run Mix tasks in response. When Claude edits an Elixir file, our PostToolUse hooks automatically:

1. Format the file with `mix format`
2. Check for compilation errors with `mix compile --warnings-as-errors`

The hook system is built on Elixir behaviours, making it easy to extend with your own custom hooks.

## Creating Custom Hooks

You can extend Claude with your own custom hooks by creating a `.claude.exs` file in your project root:

```elixir
# .claude.exs
%{
  enabled: true,
  hooks: [
    %{
      module: MyApp.Hooks.TodoChecker,
      enabled: true,
      config: %{
        todo_pattern: ~r/TODO|FIXME|HACK/,
        fail_on_todos: false
      }
    }
  ]
}
```

### Writing a Custom Hook

Custom hooks must implement the `Claude.Hooks.Hook.Behaviour`:

```elixir
defmodule MyApp.Hooks.TodoChecker do
  @behaviour Claude.Hooks.Hook.Behaviour

  @impl true
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "mix claude hooks run post_tool_use.todo_checker",
      matcher: "Edit|MultiEdit|Write"
    }
  end

  @impl true
  def description do
    "Checks for TODO comments in edited files"
  end

  @impl true
  def run(tool_name, json_params) do
    # Your hook logic here
    :ok
  end
end
```

For a complete, production-ready example, see `Claude.Hooks.PostToolUse.RelatedFilesChecker` in this library's source code.

### Hook Configuration

Hooks can receive configuration from `.claude.exs`:

```elixir
# In your hook's run/2 function:
config = Claude.Hooks.Registry.hook_config(__MODULE__)
pattern = Map.get(config, :todo_pattern, ~r/TODO/)
```

### Glob Pattern Support

The built-in `RelatedFilesChecker` hook and custom hooks can use glob patterns to dynamically find related files. This is useful for suggesting files that might need updates when certain files change.

```elixir
# .claude.exs
%{
  hooks: [
    %{
      module: Claude.Hooks.PostToolUse.RelatedFilesChecker,
      enabled: true,
      config: %{
        rules: [
          # When any lib file changes, suggest running all test files
          %{
            pattern: "lib/**/*.ex",
            suggests: [
              %{file: "test/**/*_test.exs", reason: "related test files might need updates"}
            ]
          },
          # When config.ex changes, suggest checking all files in the project
          %{
            pattern: "lib/claude/config.ex",
            suggests: [
              %{file: "lib/claude/**/*.ex", reason: "files that might use Config module"}
            ]
          }
        ]
      }
    }
  ]
}
```

Supported glob patterns:
- `*` - Match any characters except `/`
- `**` - Match any characters including `/` (recursive)
- `?` - Match single character
- `[abc]` - Match character set
- `{foo,bar}` - Match alternatives

When a glob pattern is used in the `suggests` field, all matching files will be suggested as related files that might need review or updates.

### Event Types

You can configure when your hook runs by setting the `event_type` in `.claude.exs`:

```elixir
%{
  module: MyApp.Hooks.CustomHook,
  enabled: true,
  event_type: "PreToolUse",  # Specify when the hook runs
  config: %{...}
}
```

Available event types:
- **PostToolUse** - Runs after Claude uses a tool (Edit, Write, etc.)
- **PreToolUse** - Runs before Claude uses a tool
- **UserPromptSubmit** - Runs when the user submits a prompt

If `event_type` is not specified, it will be inferred from your module's namespace (e.g., a module under `MyApp.Hooks.PostToolUse.*` will default to "PostToolUse")

### Real-World Example

The `RelatedFilesChecker` hook (included in this library) demonstrates how to create custom hooks. It suggests related files that might need updates when certain files are modified. Check out `lib/claude/hooks/post_tool_use/related_files_checker.ex` to see a complete implementation.

## Contributing

We welcome contributions! The codebase follows standard Elixir conventions:

- Run tests: `mix test`
- Format code: `mix format`

## Releasing

### Release Process

1. **Update Version**
   - Edit `mix.exs` and update the `@version` module attribute
   - Example: change `@version "0.1.0"` to `@version "0.2.0"`

2. **Update Changelog**
   - Add a new section to `CHANGELOG.md` with the version and date
   - List all changes under Added/Changed/Fixed/Removed sections

3. **Commit Changes**
   ```bash
   git add mix.exs CHANGELOG.md
   git commit -m "Release v0.2.0"
   ```

4. **Create Git Tag**
   ```bash
   git tag -a v0.2.0 -m "Version 0.2.0"
   ```

5. **Push to GitHub**
   ```bash
   git push origin main
   git push origin v0.2.0
   ```

6. **Publish to Hex**
   ```bash
   mix hex.publish
   ```

The GitHub Action will automatically create a release when you push the tag.

### Version Guidelines

Since this project uses zero-based versioning (0.x.y):

- **Patch** (0.1.0 → 0.1.1): Bug fixes, minor improvements
- **Minor** (0.1.0 → 0.2.0): New features, may include breaking changes
- **Major** (0.x.y → 1.0.0): First stable release (not used until v1.0.0)

## License

MIT
