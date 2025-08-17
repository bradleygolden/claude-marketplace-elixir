---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit]
argument-hint: "[--auto-setup]"
description: Sync nested memories, optionally auto-configure standard directories first
---

# Sync Nested Memories

I'll sync all nested memory configurations to regenerate CLAUDE.md files in the configured directories.

Arguments: `$ARGUMENTS`

## Check for Auto-Setup

! if echo "$ARGUMENTS" | grep -q "auto-setup"; then \
    echo "=== Auto-Setup Mode ==="; \
    echo "I'll first configure standard directories if they exist:"; \
    for dir in "test" "lib/$(basename $(pwd))" "lib/$(basename $(pwd))_web"; do \
      if [ -d "$dir" ]; then \
        echo "✓ Will configure: $dir"; \
      fi; \
    done; \
  fi

## Current Configuration

! echo -e "\n=== Current Nested Memories Configuration ===" && grep -A30 "nested_memories:" .claude.exs 2>/dev/null || echo "No nested memories configured"

## Running Sync

! echo -e "\n=== Syncing nested memories ===" && mix claude.install --yes

## Verification

! echo -e "\n=== Verifying generated CLAUDE.md files ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" -type f -newer .claude.exs 2>/dev/null | while read -r file; do echo "✅ Updated: $file"; done

! echo -e "\n=== All CLAUDE.md files ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" | sort

## Summary

The sync process:
1. Reads nested memory configuration from `.claude.exs`
2. For each configured directory with usage rules
3. Generates or updates `CLAUDE.md` with the specified rules
4. Claude Code will automatically discover these files

## Important Reminder

⚠️ **You need to restart Claude Code for the changes to take effect!**

The command to restart Claude Code depends on how you launched it:
- If using the CLI: Exit and run `claude` again
- If using an IDE integration: Restart the integration

Nested memories are synced! After restarting, Claude will have directory-specific context when working in those areas.
