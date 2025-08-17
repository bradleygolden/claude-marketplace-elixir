---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit]
argument-hint: "package [package2 ...]"
description: Remove dependencies from your project
---

# Remove Dependencies

I'll help you remove dependencies from your Elixir project.

Packages to remove: `$ARGUMENTS`

## Check Igniter Availability

! mix help igniter.remove > /dev/null 2>&1 && echo "Using Igniter for smart removal" || echo "Will remove dependencies manually"

## Removing Dependencies

For the packages you want to remove (`$ARGUMENTS`), I will:

1. **With Igniter** (if available):
   - Use `mix igniter.remove` to remove dependencies
   - Clean up any related configuration

2. **Without Igniter**:
   - Edit mix.exs to remove the dependencies
   - Clean mix.lock file
   - Identify any configuration that needs manual cleanup

## Current Dependencies

! mix deps --all | grep -E "$ARGUMENTS" || echo "Dependencies to remove: $ARGUMENTS"

Let me proceed with removing the requested dependencies from your project.