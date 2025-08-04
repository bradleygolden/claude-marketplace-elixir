# Generators

Claude provides Mix task generators to help you quickly create hooks and sub-agents following best practices.

## Hook Generator

Generate a new hook module using the `Claude.Hook` macro.

### Interactive Mode

```bash
mix claude.gen.hook
```

The task will guide you through selecting the event type, tools, and options.

### Non-Interactive Mode

```bash
mix claude.gen.hook <module_name> --event <event_type> [options]
```

### Options

- `--event` - The hook event type (if not provided, will prompt):
  - `post_tool_use` - Runs after tool execution
  - `pre_tool_use` - Runs before tool execution (can block)
  - `user_prompt_submit` - Runs when user submits a prompt
  - `notification` - Runs on Claude Code notifications
  - `stop` - Runs when Claude finishes responding
  - `subagent_stop` - Runs when a sub-agent finishes
  - `pre_compact` - Runs before context compaction

- `--matcher` - Tool pattern matcher (for pre_tool_use/post_tool_use events):
  - Exact match: `"write"`
  - Multiple tools: `"write,edit,multi_edit"`
  - All tools: `"*"` (default)
  - Use snake_case and comma separation for multiple tools

- `--description` - Hook description (defaults to generated description)

- `--add-to-config` - Add hook to `.claude.exs` (default: true)

### Examples

```bash
# Interactive mode - prompts for all options
mix claude.gen.hook

# Generate a formatter hook that runs after file edits
mix claude.gen.hook MyFormatter --event post_tool_use --matcher "write,edit" --description "Format files after editing"

# Generate with a custom module namespace
mix claude.gen.hook MyApp.Hooks.SecurityValidator --event pre_tool_use --matcher "bash" --description "Validate shell commands"

# Generate a notification handler
mix claude.gen.hook NotifyHandler --event notification --description "Custom notification handling"

# Generate without adding to config
mix claude.gen.hook TestHook --event stop --add-to-config false

# Semi-interactive mode - provide module name, get prompted for event
mix claude.gen.hook MyCustomHook
```

### Generated Hook Structure

The generator creates a hook module. By default, simple names are placed in the Claude namespace, but you can provide a fully-qualified module name:

```elixir
# lib/claude/hooks/post_tool_use/my_formatter.ex
defmodule Claude.Hooks.PostToolUse.MyFormatter do
  @moduledoc """
  Format files after editing
  
  This hook runs on the post_tool_use event for tools matching: Write|Edit.
  
  For more information on Claude Code hooks, see:
  - https://docs.anthropic.com/en/docs/claude-code/hooks
  - https://docs.anthropic.com/en/docs/claude-code/hooks-guide
  """
  
  use Claude.Hook,
    event: :post_tool_use,
    matcher: [:write, :edit],  # Note: matcher uses snake_case atoms
    description: "Format files after editing"
  
  @impl true
  def handle(%Claude.Hooks.Events.PostToolUse.Input{} = input) do
    # Hook implementation
    # Return :ok, {:block, reason}, {:allow, reason}, or {:deny, reason}
    :ok
  end
end
```

## Sub-Agent Generator

Create specialized AI assistants with focused capabilities.

### Interactive Mode

```bash
mix claude.gen.subagent
```

This interactive generator will prompt you for:

1. **Name** - Lowercase, hyphen-separated (e.g., `code-reviewer`)
2. **Description** - When Claude should invoke this sub-agent
3. **Tools** (optional) - Comma-separated list of allowed tools
4. **Prompt** - System prompt defining the sub-agent's behavior

### Non-Interactive Mode (AI-friendly)

```bash
mix claude.gen.subagent --name database-helper \
  --description "Assists with database queries and migrations" \
  --tools "read,grep,bash,edit" \
  --prompt "You are a database expert specializing in Ecto and PostgreSQL."
```

Perfect for automation and AI agent invocation! When all required flags (name, description, prompt) are provided, the task runs without prompts.

### Interactive Example

```
$ mix claude.gen.subagent

Enter the name for your subagent (lowercase-hyphen-separated):
> elixir-tester

Enter a description (when Claude should invoke this subagent):
> When running or writing Elixir tests

Enter tools (comma-separated snake_case, press Enter for default minimal set):
Available: bash, edit, glob, grep, ls, multi_edit, notebook_edit, notebook_read, 
           read, todo_write, web_fetch, web_search, write
⚠️  Warning: Avoid 'task' to prevent delegation loops
> read, grep, bash, edit, write

Enter the system prompt for your subagent (press Enter twice when done):
> You are an Elixir testing specialist. Your role is to:
> - Write comprehensive ExUnit tests
> - Follow testing best practices
> - Use proper test organization
> - Mock external dependencies appropriately
> 

Creating subagent 'elixir-tester'...
```

### Generated Files

The generator:

1. Adds the sub-agent to `.claude.exs`:
   ```elixir
   %{
     subagents: [
       %{
         name: "elixir-tester",
         description: "When running or writing Elixir tests",
         prompt: "...",
         tools: [:read, :grep, :bash, :edit, :write]
       }
     ]
   }
   ```

2. Creates `.claude/agents/elixir-tester.md`:
   ```markdown
   ---
   name: elixir-tester
   description: When running or writing Elixir tests
   tools: Read, Grep, Bash, Edit, Write
   ---
   
   You are an Elixir testing specialist. Your role is to:
   - Write comprehensive ExUnit tests
   - Follow testing best practices
   - Use proper test organization
   - Mock external dependencies appropriately
   ```

### Tool Selection

The generator provides guidance on tool selection:

- Warns against including the `Task` tool (can cause recursive sub-agent calls)
- Validates tool names against available Claude Code tools  
- Defaults to minimal set (read, grep, glob) if none specified
- Converts snake_case input to TitleCase for Claude Code API

### Best Practices

1. **Focused Sub-Agents**: Create sub-agents with specific, well-defined purposes
2. **Minimal Tools**: Only include tools the sub-agent actually needs
3. **Clear Descriptions**: Write descriptions that help Claude know when to invoke
4. **Detailed Prompts**: Include specific instructions and examples in prompts

## Running Generated Code

After generating hooks or sub-agents:

1. **Hooks** are automatically registered if you run `mix claude.install`
2. **Sub-agents** are available immediately after generation
3. Both can be manually edited to customize behavior

## Testing Generated Code

Generated hooks include TODO comments for implementing tests:

```elixir
# In your generated hook
def handle(input) do
  # TODO: Implement your hook logic here
  # Return :ok, {:block, reason}, {:allow, reason}, or {:deny, reason}
  :ok
end
```

Test your hooks thoroughly before using in production. Claude provides test helpers to simplify hook testing:

```elixir
# Example test using Claude.Test helpers
defmodule MyFormatterTest do
  use ExUnit.Case
  alias Claude.Test.Fixtures
  
  test "handles file formatting" do
    input = Fixtures.post_tool_use_input(
      tool_name: "Edit",
      tool_input: Fixtures.tool_input(:edit, file_path: "/test.ex")
    )
    
    json = Claude.Test.run_hook(MyFormatter, input)
    assert json["suppressOutput"] == true
  end
end
```

```bash
# Run hook tests
mix test test/claude/hooks/

# Test specific hook
mix test test/claude/hooks/post_tool_use/my_formatter_test.exs
```