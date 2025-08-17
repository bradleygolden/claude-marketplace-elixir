---
allowed-tools: [Bash, Read, WebSearch, WebFetch]
argument-hint: "[elixir-version] [otp-version]"
description: Check compatibility between Elixir, OTP, and your dependencies
---

# Elixir/OTP Compatibility Check

I'll check compatibility for: `$ARGUMENTS`

## Compatibility Matrix Research

Let me check the official Elixir/OTP compatibility matrix and your project's requirements.

### Official Compatibility

I'll research:
1. Elixir/OTP version compatibility matrix
2. Minimum and recommended OTP versions for your Elixir version
3. Known issues or breaking changes

### Project Dependencies Compatibility

! echo "Checking dependency compatibility..." && mix hex.outdated --all

! echo -e "\nAnalyzing critical dependencies..."
! mix deps | grep -E "phoenix|ecto|oban|jason|plug" || echo "Checking all dependencies..."

## Version-Specific Checks

Based on the versions you're interested in (`$ARGUMENTS`), I'll:

1. **Verify Elixir/OTP Pairing**
   - Check if the versions are officially compatible
   - Identify the recommended OTP version for your Elixir version

2. **Dependency Compatibility**
   - Check each dependency's support for target versions
   - Identify any that need upgrading

3. **Breaking Changes**
   - List any breaking changes between current and target versions
   - Identify deprecated features you may be using

4. **Migration Path**
   - Suggest incremental upgrade steps if needed
   - Highlight configuration changes required

Let me analyze your specific compatibility requirements.
