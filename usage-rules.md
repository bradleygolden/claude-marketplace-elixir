# Claude Usage Rules

Claude (not to be confused with Claude/Claude Code) is an Elixir library that provides opinionated Claude Code integration for Elixir projects. It includes tooling for deeply integrating Claude Code into your project using Elixir.

## Installation

Claude only supports igniter installation:

```bash
mix igniter.install claude
```

## Uninstalling hooks

Optionally you can uninstall the project:

```bash
mix claude.uninstall
```

This removes all settings created by this project from your project settings.

## Hook System

Claude provides a behavior-based hook system that integrates with Claude Code. All hooks implement `Claude.Hooks.Hook.Behaviour`.

### Built-in Hooks

1. **ElixirFormatter** - Automatically formats .ex/.exs files after edits
2. **CompilationChecker** - Checks for compilation errors after edits
3. **PreCommitCheck** - Validates formatting, compilation, and unused dependencies before commits

### Creating Custom Hooks

The easiest way to create a hook is using the `use` macro:

```elixir
defmodule MyProject.MyHook do
  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:edit, :write],
    description: "My custom hook that runs after edits"

  @impl Claude.Hooks.Hook.Behaviour
  def run(json_input) when is_binary(json_input) do
    # Your hook logic here
    :ok
  end
end
```

#### Options for `use` macro:

- `:event` - Hook event type (default: `:post_tool_use`)
  - `:pre_tool_use`
  - `:post_tool_use`
  - `:user_prompt_submit`
  - `:notification`
  - `:stop`
  - `:subagent_stop`
- `:matcher` - Tool matcher pattern (default: `:*`)
  - Can be a single atom: `:edit`, `:write`, `:bash`
  - Can be a list: `[:edit, :write, :multi_edit]`
  - Can be `:*` to match all tools
- `:description` - Human-readable description

For more documentation about hooks see official documentation below:

  * https://docs.anthropic.com/en/docs/claude-code/hooks
  * https://docs.anthropic.com/en/docs/claude-code/hooks-guide

ALWAYS consult the official documentation before implementing custom hooks.

#### Manual Implementation

If you need more control, you can implement the behaviour manually:

```elixir
defmodule MyProject.MyHook do
  @behaviour Claude.Hooks.Hook.Behaviour

  @impl true
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "cd $CLAUDE_PROJECT_DIR && mix claude hooks run #{identifier()}"
    }
  end

  @impl true
  def run(json_input) when is_binary(json_input) do
    # Your hook logic here
    :ok
  end

  @impl true
  def description do
    "My custom hook description"
  end

  defp identifier do
    __MODULE__
    |> Module.split()
    |> Enum.map(&Macro.underscore/1)
    |> Enum.join(".")
  end
end
```

## Settings Management

Claude uses `.claude.exs` to configure specific settings for your project that are then ported to
the `.claude` directory for use by Claude Code.

### Example `.claude.exs` configuration:

```elixir
# .claude.exs - Claude configuration for this project
%{
  # Register custom hooks (for discovery by mix claude.install)
  hooks: [
    MyProject.Hooks.CustomFormatter,
    MyProject.Hooks.SecurityChecker
  ]
}
```

For reference to the official claude settings, please see:

 * https://docs.anthropic.com/en/docs/claude-code/settings
