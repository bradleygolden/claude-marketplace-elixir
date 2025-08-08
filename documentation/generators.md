# Generators

Claude provides a Mix task generator for creating specialized AI sub-agents.

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

After generating sub-agents:

1. **Sub-agents** are available immediately after generation
2. Run `mix claude.install` to ensure the agent file is created in `.claude/agents/`
3. Sub-agents can be manually edited to customize behavior

## Hook Configuration

In v0.3.0+, hooks are configured using atom shortcuts in `.claude.exs` rather than generated modules:

```elixir
%{
  hooks: %{
    stop: [:compile, :format],
    subagent_stop: [:compile, :format],
    post_tool_use: [:compile, :format],
    pre_tool_use: [:compile, :format, :unused_deps],
    session_start: [:deps_get]  # Optional
  }
}
```

Available atom shortcuts:
- `:compile` - Runs compilation with warnings as errors
- `:format` - Checks if files need formatting
- `:unused_deps` - Checks for unused dependencies (pre_tool_use only)

For more details on the hook system, see the [Hooks Documentation](hooks.md).