---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit]
argument-hint: "package[@version] [package2[@version] ...]"
description: Add new dependencies to your project using Igniter or manual editing
---

# Add Dependencies

I'll help you add new dependencies to your Elixir project.

Packages to add: `$ARGUMENTS`

## Check Igniter Availability

! mix help igniter.add > /dev/null 2>&1 && echo "Using Igniter for smart installation" || echo "Will add dependencies manually"

## Adding Dependencies

Based on the packages you want to add (`$ARGUMENTS`), I will:

1. **With Igniter** (if available):
   - Use `mix igniter.add` to add dependencies
   - Run any associated installers automatically
   - Apply configuration changes

2. **Without Igniter**:
   - Edit mix.exs to add the dependencies
   - Run `mix deps.get` to fetch them
   - Provide any necessary configuration instructions

## Current Dependencies

! mix deps --all | head -20

Let me proceed with adding the requested dependencies to your project.
