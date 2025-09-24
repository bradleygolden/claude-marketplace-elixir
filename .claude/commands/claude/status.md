---
allowed-tools: [Bash, Read, Grep]
description: Check Claude Code installation status and configuration
---

# Claude Installation Status

I'll check the status of Claude Code integration in your project.

## Installation Overview

! echo "=== Claude Installation Status ===" && \
  if [ -f ".claude.exs" ]; then \
    echo "✓ Configuration file: .claude.exs"; \
  else \
    echo "✗ No .claude.exs configuration file"; \
  fi && \
  if [ -d ".claude" ]; then \
    echo "✓ Claude directory: .claude/"; \
  else \
    echo "✗ No .claude directory"; \
  fi

## Configuration Details

### Hooks Configuration

! echo -e "\n=== Hooks ===" && \
  if [ -d ".claude/hooks" ]; then \
    echo "Installed hooks:" && ls .claude/hooks/ | sed 's/^/  - /'; \
    echo -e "\nConfigured in .claude.exs:" && \
    grep -A10 "hooks:" .claude.exs 2>/dev/null | head -15; \
  else \
    echo "No hooks installed"; \
  fi


### Nested Memories

! echo -e "\n=== Nested Memories ===" && \
  grep -A20 "nested_memories:" .claude.exs 2>/dev/null || echo "No nested memories configured"

! echo -e "\nGenerated CLAUDE.md files:" && \
  find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" 2>/dev/null | sed 's/^/  - /'

### MCP Servers

! echo -e "\n=== MCP Servers ===" && \
  if [ -f ".mcp.json" ]; then \
    echo "MCP configuration exists:" && \
    cat .mcp.json | grep '"name"' | sed 's/.*"name"://; s/[",]//g' | sed 's/^/  - /'; \
  else \
    echo "No MCP servers configured"; \
  fi

### Settings

! echo -e "\n=== Local Settings ===" && \
  if [ -f ".claude/settings.json" ]; then \
    echo "Settings file exists with configurations:" && \
    cat .claude/settings.json | grep -E '^\s*"[^"]+":' | sed 's/^/  /'; \
  else \
    echo "No local settings file"; \
  fi

## Usage Rules Status

! echo -e "\n=== Usage Rules ===" && \
  echo "Checking for usage_rules dependency..." && \
  mix deps | grep usage_rules || echo "usage_rules not installed"

! echo -e "\nAvailable usage rules:" && \
  mix usage_rules.sync --list 2>/dev/null | head -10 || echo "Cannot list usage rules"

## Quick Actions

Based on the status above:

! if [ ! -f ".claude.exs" ]; then \
    echo "→ Run '/claude/install' to set up Claude integration"; \
  elif [ ! -d ".claude/hooks" ]; then \
    echo "→ Run 'mix claude.install' to install configured components"; \
  else \
    echo "→ Run '/claude/install --yes' to update installation"; \
    echo "→ Run '/memory/nested-sync' to update nested memories"; \
    echo "→ Run '/hooks' to manage hooks"; \
  fi

## Health Check

! echo -e "\n=== Health Check ===" && \
  errors=0 && \
  if [ -f ".claude.exs" ]; then \
    echo "✓ Configuration exists"; \
  else \
    echo "⚠ Missing .claude.exs" && errors=$((errors+1)); \
  fi && \
  if [ -d ".claude/hooks" ] && [ -f ".claude.exs" ]; then \
    echo "✓ Hooks match configuration"; \
  elif [ -f ".claude.exs" ] && grep -q "hooks:" .claude.exs; then \
    echo "⚠ Hooks configured but not installed" && errors=$((errors+1)); \
  else \
    echo "✓ No hooks expected"; \
  fi && \
  if [ $errors -eq 0 ]; then \
    echo -e "\n✅ Claude installation is healthy"; \
  else \
    echo -e "\n⚠ Found $errors issue(s) - run '/claude/install' to fix"; \
  fi
