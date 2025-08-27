---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit]
argument-hint: "[show|edit|validate]"
description: Manage .claude.exs configuration file
---

# Claude Configuration Management

I'll help you manage your `.claude.exs` configuration file.

Command: `$ARGUMENTS`

## Current Configuration

! echo "=== .claude.exs Configuration ===" && \
  if [ -f ".claude.exs" ]; then \
    echo "Configuration file exists" && \
    wc -l .claude.exs | awk '{print "Lines: " $1}'; \
  else \
    echo "No .claude.exs file found"; \
    echo "Would you like me to create one?"; \
  fi

## Action Handler

! case "$ARGUMENTS" in \
    "show") \
      echo -e "\n=== Full Configuration ===" && \
      cat .claude.exs 2>/dev/null || echo "No configuration file"; \
      ;; \
    "validate") \
      echo -e "\n=== Validating Configuration ===" && \
      mix run -e "File.read!(\".claude.exs\") |> Code.eval_string() |> elem(0) |> IO.inspect(label: \"Valid configuration\")" 2>&1 || echo "Configuration has syntax errors"; \
      ;; \
    "edit") \
      echo -e "\n=== Ready to Edit Configuration ==="; \
      echo "I'll help you edit the configuration file."; \
      echo "Current sections available:"; \
      grep -E "^\s*(hooks|subagents|nested_memories|mcp_servers|auto_install_deps):" .claude.exs 2>/dev/null | sed 's/:.*/:/' | sed 's/^/  - /' || echo "  No sections found"; \
      ;; \
    *) \
      echo -e "\n=== Configuration Sections ==="; \
      if [ -f ".claude.exs" ]; then \
        echo "Hooks:" && grep -c "hooks:" .claude.exs | xargs echo "  Configured:"; \
        echo "Subagents:" && grep -c "subagents:" .claude.exs | xargs echo "  Configured:"; \
        echo "Nested memories:" && grep -c "nested_memories:" .claude.exs | xargs echo "  Configured:"; \
        echo "MCP servers:" && grep -c "mcp_servers:" .claude.exs | xargs echo "  Configured:"; \
      fi; \
      ;; \
  esac

## Configuration Structure

The `.claude.exs` file supports these sections:

### Hooks
```elixir
hooks: %{
  pre_tool_use: [:compile, :format],
  post_tool_use: [:compile, :format],
  stop: [:compile, :format],
  subagent_stop: [:compile, :format]
}
```

### Subagents
```elixir
subagents: [
  %{
    name: "agent-name",
    description: "When to use this agent",
    prompt: "System prompt",
    tools: [:read, :write, :edit],
    usage_rules: [:usage_rules_elixir]
  }
]
```

### Nested Memories
```elixir
nested_memories: %{
  "test" => ["usage_rules:elixir", "usage_rules:otp"],
  "lib/app_name" => ["usage_rules:elixir", "usage_rules:otp"]
}
```

### MCP Servers
```elixir
mcp_servers: [
  :tidewave,
  {:custom_server, [port: 5000]}
]
```

### Other Settings
```elixir
auto_install_deps?: true  # Auto-install missing dependencies
```

## Quick Actions

Based on your configuration:

! if [ ! -f ".claude.exs" ]; then \
    echo "→ Create a new configuration with default settings"; \
  else \
    echo "→ Use '/claude/config edit' to modify configuration"; \
    echo "→ Use '/claude/config validate' to check for syntax errors"; \
    echo "→ Use '/claude/install' to apply configuration changes"; \
  fi

## Related Commands

- `/claude/install` - Apply configuration changes
- `/memory/nested-add` - Add nested memory configuration
- `/hooks` - Manage hooks interactively
- `/claude/status` - Check installation status

After making changes, remember to:
1. Run `/claude/install` to apply changes (takes effect immediately)
