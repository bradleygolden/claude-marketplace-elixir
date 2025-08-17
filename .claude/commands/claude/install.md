---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit, Grep]
argument-hint: "[--yes] [--with-auto-memories]"
description: Run claude.install to set up hooks, subagents, MCP servers, and nested memories
---

# Claude Installation

I'll run the Claude installation process to set up all Claude Code integrations for your project.

Arguments: `$ARGUMENTS`

## Pre-Installation Check

### Current Claude Configuration

! echo "=== Checking .claude.exs configuration ===" && if [ -f ".claude.exs" ]; then echo "✓ .claude.exs exists"; grep -E "hooks:|subagents:|nested_memories:|mcp_servers:" .claude.exs | head -20; else echo "⚠ No .claude.exs file found - will create default"; fi

### Check Installation Status

! echo -e "\n=== Current installation status ===" && ls -la .claude/ 2>/dev/null || echo "No .claude directory yet"

! echo -e "\n=== Checking for existing hooks ===" && ls -la .claude/hooks/ 2>/dev/null || echo "No hooks installed"

! echo -e "\n=== Checking for existing subagents ===" && ls -la .claude/agents/ 2>/dev/null || echo "No subagents installed"

## Auto-Configure Nested Memories (if requested)

! if echo "$ARGUMENTS" | grep -q "with-auto-memories"; then \
    echo -e "\n=== Auto-configuring nested memories for standard directories ==="; \
    for dir in "test" "lib/$(basename $(pwd))" "lib/$(basename $(pwd))_web"; do \
      if [ -d "$dir" ]; then \
        echo "✓ Will configure nested memories for: $dir"; \
      fi; \
    done; \
    echo "These will get base rules (usage_rules:elixir, usage_rules:otp) plus detected package rules"; \
  fi

## Running Installation

! echo -e "\n=== Running mix claude.install ===" && if echo "$ARGUMENTS" | grep -q "\-\-yes"; then mix claude.install --yes; else mix claude.install; fi

## Post-Installation Verification

! echo -e "\n=== Verifying installation ===" 

! echo -e "\n✓ Hooks installed:" && ls .claude/hooks/ 2>/dev/null | head -10 || echo "No hooks found"

! echo -e "\n✓ Subagents installed:" && ls .claude/agents/ 2>/dev/null | head -10 || echo "No subagents found"

! echo -e "\n✓ Settings file:" && if [ -f ".claude/settings.json" ]; then echo "Settings.json exists"; else echo "No settings.json created"; fi

! echo -e "\n✓ MCP configuration:" && if [ -f ".mcp.json" ]; then cat .mcp.json | head -20; else echo "No .mcp.json file"; fi

! echo -e "\n✓ Nested CLAUDE.md files generated:" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" | head -10

## What Was Installed

The installation process configured:

1. **Hooks** - Automatic code formatting, compilation checks, and pre-commit validation
2. **Subagents** - Specialized AI agents defined in `.claude.exs`
3. **MCP Servers** - Model Context Protocol servers (if configured)
4. **Nested Memories** - Directory-specific CLAUDE.md files with usage rules
5. **Usage Rules** - Package-specific guidelines synced to CLAUDE.md

## Important Next Steps

⚠️ **RESTART REQUIRED**: You must restart Claude Code for these changes to take effect!

To restart:
- If using CLI: Exit (Ctrl+C or Ctrl+D) and run `claude` again
- If using IDE integration: Restart the integration

After restarting, Claude will have:
- Active hooks for code quality
- Access to specialized subagents
- Directory-specific context from nested memories
- Package usage rules for better code generation

## Additional Commands

After installation, you can:
- View hooks: `/hooks`
- Manage memories: `/memory/nested-list`
- Check configuration: `cat .claude.exs`
- Update settings: `/config`
