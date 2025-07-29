# Subagents Usage Rules

## Overview

Subagents in Claude projects should be configured via `.claude.exs` and installed using `mix claude.install`. This ensures consistent setup and proper integration with your project.

## Key Concepts

### Clean Slate Limitation
Subagents start with a clean slate on every invocation - they have no memory of previous interactions or context. This means:
- Context gathering operations (file reads, searches) are repeated each time
- Previous decisions or analysis must be rediscovered
- Consider embedding critical context directly in the prompt if repeatedly needed

### Tool Inheritance Behavior
When `tools` is omitted, subagents inherit ALL tools including dynamically loaded MCP tools. When specified:
- The list becomes static - new MCP tools won't be available
- Subagents without `:task` tool cannot delegate to other subagents
- Tool restrictions are enforced at invocation time, not definition time

## Configuration in .claude.exs

### Basic Structure

```elixir
%{
  subagents: [
    %{
      name: "Your Agent Name",
      description: "Clear description of when to use this agent",
      prompt: "Detailed system prompt for the agent",
      tools: [:read, :write, :edit],  # Optional - defaults to all tools
      usage_rules: ["package:rule"]    # Optional - includes specific usage rules
    }
  ]
}
```

### Required Fields

- **name**: Human-readable name (will be converted to kebab-case for filename)
- **description**: Clear trigger description for automatic delegation
- **prompt**: The system prompt that defines the agent's expertise

### Optional Fields

- **tools**: List of tool atoms to restrict access (defaults to all tools if omitted)
- **usage_rules**: List of usage rules to include in the agent's prompt

## References

- [Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents.md)
- [Claude Code Settings](https://docs.anthropic.com/en/docs/claude-code/settings.md)
- [Claude Code Hooks](https://docs.anthropic.com/en/docs/claude-code/hooks.md)
