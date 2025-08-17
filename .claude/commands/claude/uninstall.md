---
allowed-tools: [Bash, Read, Edit]
argument-hint: "[--keep-config] [--keep-memories]"
description: Uninstall Claude Code integrations (hooks, subagents, etc.)
---

# Claude Uninstallation

I'll help you uninstall Claude Code integrations from your project.

Arguments: `$ARGUMENTS`

## Current Installation Status

! echo "=== Checking current Claude installation ===" && ls -la .claude/ 2>/dev/null || echo "No .claude directory found"

! echo -e "\n=== Installed components ===" && \
  (ls .claude/hooks/ 2>/dev/null | wc -l | xargs echo "Hooks:") && \
  (ls .claude/agents/ 2>/dev/null | wc -l | xargs echo "Subagents:") && \
  ([ -f .claude/settings.json ] && echo "Settings: ✓") && \
  ([ -f .mcp.json ] && echo "MCP config: ✓")

## What Will Be Removed

Based on your options:

! if echo "$ARGUMENTS" | grep -q "keep-config"; then \
    echo "✓ Keeping .claude.exs configuration file"; \
  else \
    echo "⚠ Will remove .claude.exs configuration file"; \
  fi

! if echo "$ARGUMENTS" | grep -q "keep-memories"; then \
    echo "✓ Keeping CLAUDE.md memory files"; \
  else \
    echo "⚠ Will remove generated CLAUDE.md files (except root)"; \
  fi

Standard removal includes:
- `.claude/hooks/` - All hook scripts
- `.claude/agents/` - All subagent files
- `.claude/settings.json` - Local settings
- `.mcp.json` - MCP server configuration

## Removing Claude Components

! echo -e "\n=== Removing Claude installation ==="

! echo "Removing hooks..." && rm -rf .claude/hooks/ 2>/dev/null && echo "✓ Hooks removed" || echo "No hooks to remove"

! echo "Removing subagents..." && rm -rf .claude/agents/ 2>/dev/null && echo "✓ Subagents removed" || echo "No subagents to remove"

! echo "Removing settings..." && rm -f .claude/settings.json 2>/dev/null && echo "✓ Settings removed" || echo "No settings to remove"

! echo "Removing MCP config..." && rm -f .mcp.json 2>/dev/null && echo "✓ MCP config removed" || echo "No MCP config to remove"

! if echo "$ARGUMENTS" | grep -q "keep-config"; then \
    echo "Keeping .claude.exs as requested"; \
  else \
    echo "Removing .claude.exs..." && rm -f .claude.exs 2>/dev/null && echo "✓ Config removed" || echo "No config to remove"; \
  fi

! if echo "$ARGUMENTS" | grep -q "keep-memories"; then \
    echo "Keeping CLAUDE.md files as requested"; \
  else \
    echo "Note: Nested CLAUDE.md files in subdirectories are kept by default"; \
    echo "Remove them manually if needed: find . -name 'CLAUDE.md' -not -path './CLAUDE.md'"; \
  fi

## Clean Up Empty Directories

! echo -e "\n=== Cleaning up ===" && \
  if [ -d ".claude" ] && [ -z "$(ls -A .claude)" ]; then \
    rmdir .claude && echo "✓ Removed empty .claude directory"; \
  else \
    echo "✓ .claude directory has remaining files or doesn't exist"; \
  fi

## Verification

! echo -e "\n=== Verification ===" && \
  if [ -d ".claude" ]; then \
    echo "Remaining .claude contents:" && ls -la .claude/; \
  else \
    echo "✓ All Claude components have been removed"; \
  fi

## Summary

Claude Code integration has been uninstalled from this project.

To reinstall later:
- Run `/claude/install` or `mix claude.install`
- Your `.claude.exs` configuration can be recreated if needed

Note: This does not affect:
- Your global Claude Code installation
- User-level settings in `~/.claude/`
- The root CLAUDE.md file (project memory)
