---
allowed-tools: [Bash, Read, Grep]
description: List all nested memory configurations and their generated CLAUDE.md files
---

# List Nested Memory Configurations

I'll show you all configured nested memories and their corresponding CLAUDE.md files.

## Current Configuration in .claude.exs

! echo "=== Nested Memories Configuration ===" && grep -A20 "nested_memories:" .claude.exs 2>/dev/null || echo "No nested memories configured"

## Generated CLAUDE.md Files

! echo -e "\n=== Finding CLAUDE.md files in project ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" 2>/dev/null | while read -r file; do echo "📁 $file"; head -5 "$file" | sed 's/^/   /'; echo; done

## Directory Structure

! echo -e "\n=== Directories with CLAUDE.md files ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" -exec dirname {} \; | sort -u

## Usage Rules in Each CLAUDE.md

! echo -e "\n=== Usage Rules per Directory ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" | while read -r file; do echo "📄 $file:"; grep -E "^## .* usage$" "$file" 2>/dev/null | sed 's/^/   /' || echo "   (No usage rules found)"; done

## Summary

Based on the scan above:
- Nested memories help Claude understand directory-specific contexts
- Each directory can have its own CLAUDE.md with relevant usage rules
- These are automatically synced when running `mix claude.install`

To manage nested memories:
- Add new: `/memory/nested-add <directory> <rule1> [rule2...]`
- Remove: `/memory/nested-remove <directory>`
- Sync all: `/memory/nested-sync`