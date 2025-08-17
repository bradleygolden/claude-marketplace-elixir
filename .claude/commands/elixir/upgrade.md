---
allowed-tools: [Bash, Read, Edit, Write, MultiEdit, Grep, WebSearch, WebFetch]
argument-hint: "[target-version] [--check-only] [--compatibility-report]"
description: Intelligent Elixir/OTP version upgrade assistant with compatibility analysis
---

# Elixir/OTP Version Upgrade Assistant

I'll help you upgrade your Elixir and OTP versions by analyzing your project's requirements and dependencies.

Request: `$ARGUMENTS`

## Step 1: Current Environment Analysis

### Check Current Versions

! echo "Current Elixir version:" && elixir --version

! echo "Current Erlang/OTP version:" && erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

### Project Configuration

! echo "Checking project's Elixir version requirement..."
! grep -A2 "elixir:" mix.exs || echo "No explicit Elixir version requirement found"

! echo "Checking .tool-versions (asdf)..."
! cat .tool-versions 2>/dev/null || echo "No .tool-versions file found"

! echo "Checking .tool-versions.lock..."
! cat .tool-versions.lock 2>/dev/null || echo "No .tool-versions.lock file found"

### Dependency Compatibility Analysis

! echo "Analyzing dependencies for version constraints..."
! mix deps | grep -E "elixir|otp|erlang" || echo "Checking all dependencies..."

! mix hex.outdated --all

## Step 2: Compatibility Research

Based on the analysis above, I need to:

1. **Check Elixir/OTP Compatibility Matrix**
   - Review which OTP versions are compatible with target Elixir version
   - Identify minimum and recommended OTP versions

2. **Analyze Dependencies**
   - Check each dependency's compatibility with target versions
   - Look for known breaking changes
   - Review deprecation warnings

3. **Project-Specific Considerations**
   - Phoenix version compatibility (if applicable)
   - Ecto and database adapter requirements
   - Any native dependencies (NIFs)
   - Docker/deployment configurations

## Step 3: Version Management Tool Detection

! echo "Detecting version management tools..."
! if command -v asdf >/dev/null 2>&1; then echo "✓ asdf detected"; fi
! if command -v rtx >/dev/null 2>&1; then echo "✓ rtx detected"; fi
! if command -v mise >/dev/null 2>&1; then echo "✓ mise detected"; fi
! if [ -f ".tool-versions" ]; then echo "✓ .tool-versions file exists"; fi

## Step 4: Upgrade Strategy

Based on my analysis, I'll determine:

1. **Target Versions**
   - Recommended Elixir version
   - Compatible OTP version
   - Any dependency updates needed

2. **Upgrade Path**
   - Direct upgrade vs incremental
   - Required dependency updates
   - Configuration changes needed

3. **Risk Assessment**
   - Breaking changes to address
   - Deprecated features in use
   - Testing requirements

## Step 5: Project Files to Update

I'll need to check and potentially update:

- `mix.exs` - Elixir version requirement
- `.tool-versions` - Version management file
- `.formatter.exs` - Formatter configuration
- `Dockerfile` (if exists) - Base image versions
- `.github/workflows/*.yml` - CI/CD configurations
- `config/*.exs` - Configuration files for deprecations

## Step 6: Implementation Plan

After analyzing everything, I'll:

1. Create backups of critical files
2. Update version specifications
3. Install new versions (with tool-specific commands)
4. Update dependencies for compatibility
5. Address any deprecation warnings
6. Run comprehensive tests

Let me proceed with the analysis and create a detailed upgrade plan for your specific project.
