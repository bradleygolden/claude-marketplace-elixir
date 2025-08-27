# Sub-Agents Guide

Sub-agents are specialized AI assistants that handle specific tasks. Claude delegates work to them when appropriate.

## What Are Sub-Agents?

Think of sub-agents as expert consultants:
- **Code Reviewer** - Reviews your code for quality and security
- **Debugger** - Investigates errors and fixes bugs  
- **Tester** - Writes and runs tests for your code
- **Database Expert** - Handles SQL and database operations

Each has its own context and specialized knowledge.

## Quick Start

Sub-agents are created as Markdown files in `.claude/agents/` (for your project) or `~/.claude/agents/` (personal). The easiest way is to ask the Meta Agent to create one for you:

```
> Create a new sub-agent for database optimization
# Meta Agent will generate a complete sub-agent file
```

## Example: Code Reviewer

Here's a simple code reviewer sub-agent:

```markdown
---
name: code-reviewer
description: Reviews code for quality, security, and best practices. Use after writing or editing code.
tools: Read, Grep, Bash
---

You are a senior code reviewer focused on code quality and security.

When reviewing code:
1. Check for common issues (naming, structure, security)
2. Verify error handling and input validation  
3. Look for performance problems
4. Suggest improvements with examples

Provide feedback in order of priority:
- Critical issues (must fix)
- Important suggestions (should fix)  
- Nice-to-have improvements

Be constructive and specific.
```

## File Locations

Sub-agents are stored as Markdown files:
- **Project:** `.claude/agents/` (shared with team)
- **Personal:** `~/.claude/agents/` (just for you)

## Common Sub-Agent Types

**Code Quality:**
- Code reviewer for best practices
- Security auditor for vulnerabilities
- Performance optimizer

**Development:**
- Test writer and runner
- Database/SQL expert
- API designer
- Documentation writer

**Project-Specific:**
- Domain expert for your business logic
- Integration specialist for your APIs
- Deployment coordinator

## Using Sub-Agents

**Automatic:** Claude uses them when tasks match their description
```
> I just wrote a new user authentication module
# Claude might delegate to your security sub-agent
```

**Explicit:** Request a specific sub-agent
```
> Use the code-reviewer sub-agent to check my recent changes
> Have the database expert optimize this query
```

## Best Practices

**Good Descriptions:**
- "Use for SQL queries and database optimization"
- "Reviews code for security vulnerabilities"  
- "Writes and runs tests for new features"

**Bad Descriptions:**
- "Helps with stuff"
- "Does things"
- "General purpose assistant"

**Tool Selection:**
- **Read, Grep, Bash** - Most common combination
- **Limited tools** - Faster execution, clearer purpose
- **All tools** - Only if the sub-agent really needs them

## Built-in Sub-Agents

The Meta Agent comes pre-installed to help create new sub-agents:

```
> Create a new sub-agent for testing LiveView components
# Meta Agent will generate a complete sub-agent for you
```

This is the only built-in sub-agent - you create others by asking the Meta Agent.

## Configuration

Sub-agents are configured in `.claude.exs`:

```elixir
%{
  subagents: [
    %{
      name: "code-reviewer",
      description: "Reviews code for quality and security issues",
      tools: ["Read", "Grep", "Bash"],
      system_prompt: "You are a code reviewer..."
    }
  ]
}
```

But it's easier to ask the Meta Agent to create one for you.

## Need More?

- **Quick reference:** [Sub-Agents Cheatsheet](../cheatsheets/subagents.cheatmd)
- **Official docs:** [Claude Code Sub-Agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)