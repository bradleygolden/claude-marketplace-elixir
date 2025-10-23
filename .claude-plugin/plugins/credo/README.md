# credo

Credo static code analysis plugin for Claude Code with **context-aware feedback**.

## Installation

```bash
claude
/plugin install credo@elixir
```

## Requirements

- Elixir installed and available in PATH
- Mix available
- Credo installed in your project (add `{:credo, "~> 1.7", only: [:dev, :test], runtime: false}` to mix.exs)
- Run from an Elixir project directory (with mix.exs)

## Features

### Automatic Hooks

**PostToolUse - After file edits:**
- Automatically runs `mix credo` on edited .ex/.exs files
- **Informs Claude via context** - Claude sees the output and can address issues automatically
- Non-blocking - work continues while Claude considers the feedback

**PreToolUse - Before git commits:**
- Runs `mix credo --strict` before any `git commit`
- Shows output in transcript mode for user visibility
- Non-blocking by default (can be configured to block on critical issues)

## How It Works: Context-Aware Feedback

This plugin uses **JSON output with `additionalContext`** to inform Claude Code about code quality issues without blocking your workflow.

### PostToolUse Hook Behavior (.claude-plugin/plugins/credo/scripts/post-edit-check.sh:1)

When you edit an Elixir file:

1. **Credo runs** on the modified file
2. **If issues are found**:
   - Outputs JSON with `hookSpecificOutput.additionalContext`
   - Exit code 0 (non-blocking)
   - Output truncated to 30 lines (with note about full output command)
   - Claude sees the credo output in its context
   - Claude can address issues automatically or inform you
3. **If no issues**:
   - Suppresses output (`suppressOutput: true`)
   - No noise in your workflow

**Exit code behavior:**
- Exit 0 with JSON output = Claude sees context, no blocking
- This is different from exit 2 which would block and require fixing

**Output truncation:**
- Output limited to 30 lines to avoid overwhelming context
- When truncated, shows: "[Output truncated: showing 30 of N lines]"
- Provides command to see full output: `mix credo "file_path"`

### PreToolUse Hook Behavior (.claude-plugin/plugins/credo/scripts/pre-commit-check.sh:1)

Before git commits:

1. **Credo runs** in strict mode
2. **By default** (non-blocking):
   - Outputs to stdout with exit code 0
   - Output truncated to 30 lines (with note about full output command)
   - Shows in transcript mode (Ctrl-R) for user visibility
   - Does NOT inform Claude (PreToolUse limitation)
   - Commit proceeds normally
3. **Optional blocking mode** (commented in script):
   - Uncomment the blocking code to use `permissionDecision: "deny"`
   - This shows credo output to Claude and blocks the commit
   - Claude must address issues before commit can proceed

**Why different from PostToolUse?**
- PreToolUse hooks cannot add context without blocking (no `additionalContext` field)
- Options are: allow, deny, or ask - no "inform without blocking"
- Default is non-blocking to match the plugin's design philosophy

**Output truncation:**
- Output limited to 30 lines to avoid overwhelming the transcript
- When truncated, shows: "[Output truncated: showing 30 of N lines]"
- Provides command to see full output: `mix credo --strict`

## Customization

To **enable blocking on commits** when credo finds issues:

1. Edit `.claude-plugin/plugins/credo/scripts/pre-commit-check.sh`
2. Comment out the non-blocking section (lines with `echo` and `exit 0`)
3. Uncomment the blocking section (the `jq -n` command with `permissionDecision: "deny"`)
4. Restart your Claude Code session for changes to take effect

## Technical Details

**PostToolUse hook:**
- Uses JSON output format
- Field: `hookSpecificOutput.additionalContext`
- Exit code: 0 (success, non-blocking)
- Result: Claude sees output in its context window

**PreToolUse hook:**
- Uses stdout output for transcript mode
- Exit code: 0 (success, non-blocking)
- Result: User sees output with Ctrl-R, Claude does not

**Script location:**
- Scripts use `${CLAUDE_PLUGIN_ROOT}` environment variable
- Timeout: 30 seconds per hook
- Runs in parallel with other hooks
