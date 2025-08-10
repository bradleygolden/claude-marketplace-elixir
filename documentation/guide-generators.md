# Generators

Claude provides a Mix task generator for creating specialized AI sub-agents.

> 📋 **Quick Reference**: See the [Generators Cheatsheet](../cheatsheets/generators.cheatmd) for command options and examples.

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

1. Adds the sub-agent configuration to `.claude.exs`
2. Creates the agent file in `.claude/agents/`

For details on the configuration format and fields, see the [Sub-Agents Guide](guide-subagents.md#configuration-format).

### Tool Selection

The generator provides guidance on tool selection:

- Warns against including the `Task` tool (can cause recursive sub-agent calls)
- Validates tool names against available Claude Code tools  
- Defaults to minimal set (read, grep, glob) if none specified
- Converts snake_case input to TitleCase for Claude Code API

### Best Practices

For sub-agent design principles and best practices, see:
- [Important Design Principles](guide-subagents.md#important-design-principles) in the Sub-Agents Guide
- [Performance Best Practices](guide-subagents.md#performance-best-practices) for optimization tips

## After Generation

1. The sub-agent is added to `.claude.exs`
2. Run `mix claude.install` to create the agent file in `.claude/agents/`
3. The sub-agent is immediately available to Claude

For more ways to create sub-agents, including using the Meta Agent, see [Creating Sub-Agents](guide-subagents.md#creating-sub-agents).

## See Also

- [Sub-Agents Guide](guide-subagents.md) - Complete sub-agent documentation and examples
- [Hooks Guide](guide-hooks.md) - Hook configuration and atom shortcuts
- [Usage Rules Guide](guide-usage-rules.md) - Integrating best practices into sub-agents