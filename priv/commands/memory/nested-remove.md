---
allowed-tools: [Bash, Read, Edit, MultiEdit]
argument-hint: "directory"
description: Remove nested memory configuration for a directory
---

# Remove Nested Memory Configuration

I'll remove the nested memory configuration for the specified directory.

Target directory: `$ARGUMENTS`

## Current Configuration

Let me check the current nested memories configuration:

! echo "Current nested memories:" && grep -A20 "nested_memories:" .claude.exs 2>/dev/null || echo "No nested memories configured"

## Remove Configuration

I'll remove the nested memory configuration for `$ARGUMENTS` from `.claude.exs`.

This will:
1. Remove the directory mapping from `nested_memories` in `.claude.exs`
2. Optionally clean up the generated CLAUDE.md file

## Check for Existing CLAUDE.md

! if [ -f "$ARGUMENTS/CLAUDE.md" ]; then echo "Found CLAUDE.md in $ARGUMENTS"; echo "This file will need to be manually removed or updated."; else echo "No CLAUDE.md file found in $ARGUMENTS"; fi

## Update .claude.exs

I'll now update the `.claude.exs` file to remove the nested memory configuration for this directory.

After removal, you may want to:
- Delete the `$ARGUMENTS/CLAUDE.md` file if it's no longer needed
- Or keep it for manual maintenance
- Run `mix claude.install` to ensure consistency

Let me proceed with removing the configuration.