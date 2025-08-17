---
allowed-tools: [Bash, Read, Grep]
description: Check all memory files (CLAUDE.md) in the project hierarchy
---

# Memory Files Check

I'll scan for all CLAUDE.md files in your project and show how they're organized.

## Memory Hierarchy

Claude Code loads memories in this order (higher precedence first):
1. **Project memory**: `./CLAUDE.md` 
2. **User memory**: `~/.claude/CLAUDE.md`
3. **Nested memories**: Directory-specific `CLAUDE.md` files

## Project Root Memory

! echo "=== Root CLAUDE.md ===" && if [ -f "CLAUDE.md" ]; then wc -l CLAUDE.md | awk '{print "Lines: " $1}'; echo "First 10 lines:"; head -10 CLAUDE.md; else echo "No root CLAUDE.md found"; fi

## User Global Memory

! echo -e "\n=== User CLAUDE.md ===" && if [ -f "$HOME/.claude/CLAUDE.md" ]; then wc -l "$HOME/.claude/CLAUDE.md" | awk '{print "Lines: " $1}'; echo "First 10 lines:"; head -10 "$HOME/.claude/CLAUDE.md"; else echo "No user CLAUDE.md found"; fi

## Nested Memory Files

! echo -e "\n=== Nested CLAUDE.md Files ===" && find . -name "CLAUDE.md" -not -path "./CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" 2>/dev/null | sort | while read -r file; do echo "📁 $file"; wc -l "$file" | awk '{print "   Lines: " $1}'; done

## Memory File Sizes

! echo -e "\n=== Memory File Sizes ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" -exec ls -lh {} \; | awk '{print $9 ": " $5}'

## Usage Rules Distribution

! echo -e "\n=== Usage Rules per Memory File ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" | while read -r file; do echo "$file:"; grep "^## .* usage$" "$file" 2>/dev/null | wc -l | awk '{print "  Usage rule sections: " $1}'; done

## Imports Check

! echo -e "\n=== Files with @imports ===" && find . -name "CLAUDE.md" -not -path "./.git/*" -not -path "./_build/*" -not -path "./deps/*" -exec grep -l "^@" {} \; 2>/dev/null || echo "No @imports found"

## Summary

The memory system helps Claude understand:
- Project-wide conventions (root CLAUDE.md)
- Directory-specific patterns (nested CLAUDE.md)
- Personal preferences (user CLAUDE.md)

Use `/memory/nested-list` to see nested memory configuration.