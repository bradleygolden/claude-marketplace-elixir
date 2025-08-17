---
allowed-tools: [Bash, Read, Grep]
description: Check current Elixir/OTP versions and project requirements
---

# Elixir/OTP Version Check

I'll check your current Elixir and OTP versions along with project requirements.

## Current System Versions

! echo "=== Installed Versions ===" && elixir --version

! echo -e "\n=== OTP Release ===" && erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell

## Project Requirements

! echo -e "\n=== Project's Elixir Requirement ===" && grep -A2 "elixir:" mix.exs || echo "No explicit requirement in mix.exs"

! echo -e "\n=== Version Management Files ===" && ls -la .tool-versions* 2>/dev/null || echo "No version files found"

! if [ -f .tool-versions ]; then echo -e "\n=== .tool-versions Content ===" && cat .tool-versions; fi

## Dependencies Version Requirements

! echo -e "\n=== Key Dependencies ===" && mix deps | head -20

! echo -e "\n=== Checking for Version Conflicts ===" && mix deps.compile 2>&1 | grep -i "version" || echo "No version warnings detected"

## Compatibility Notes

Based on the versions above, I can help you:
- Understand if your versions are compatible
- Identify any version mismatches
- Plan upgrades if needed (use `/elixir/upgrade`)
- Check specific compatibility (use `/elixir/compatibility`)