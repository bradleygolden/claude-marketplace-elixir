# Exit Code Strategy for Credo Plugin

This document explains how the credo plugin uses exit codes and JSON output to inform Claude Code via context without blocking your workflow.

## Quick Reference

| Hook Type | Exit Code | Output Method | Result |
|-----------|-----------|---------------|--------|
| PostToolUse (issues found) | 0 | JSON with `additionalContext` | Claude sees issues in context, no blocking |
| PostToolUse (no issues) | 0 | JSON with `suppressOutput: true` | Silent, no noise |
| PreToolUse (issues found) | 0 | stdout text | User sees in transcript (Ctrl-R), Claude does not |
| PreToolUse (no issues) | 0 | JSON with `suppressOutput: true` | Silent |

## How It Works

### PostToolUse Hook (After Edits)

**Goal:** Inform Claude about code quality issues so it can address them automatically.

**Implementation:**
```bash
# Exit code 0 (non-blocking) + JSON output
exit 0
```

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Credo analysis: <output here>"
  }
}
```

**Why this works:**
- Exit code 0 = success, no blocking
- JSON `additionalContext` = Claude sees the credo output in its context window
- Claude can now automatically fix issues or inform you about them

**What happens:**
1. You edit a file
2. Credo runs automatically
3. If issues found → Claude sees them in context (truncated to 30 lines)
4. Claude may auto-fix issues on next action
5. Your work continues uninterrupted

**Output management:**
- Truncates to 30 lines max to avoid context overflow
- Shows truncation notice with full output command
- Example: "[Output truncated: showing 30 of 150 lines] Run 'mix credo "file.ex"' to see the full output."

### PreToolUse Hook (Before Commits)

**Goal:** Show credo results to user without blocking commits (default), with option to block.

**Default Implementation (non-blocking):**
```bash
# Exit code 0 (non-blocking) + stdout
echo "$CREDO_OUTPUT"
exit 0
```

**Why this works:**
- Exit code 0 = no blocking
- stdout output = shown in transcript mode (Ctrl-R)
- Commit proceeds normally
- Output truncated to 30 lines to avoid transcript clutter

**Limitation:**
- PreToolUse hooks cannot add context to Claude without blocking
- No `additionalContext` field available for PreToolUse
- Only options: allow (with/without reason shown to user), deny (with reason shown to Claude), or ask (user confirms)

**Optional Blocking Mode (commented out):**
```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Credo found issues: <output>"
  }
}
```

This would:
- Block the git commit
- Show credo output to Claude
- Claude must address issues before commit can proceed

## Exit Code Reference

From Claude Code hooks documentation:

| Exit Code | Behavior | stdout | stderr |
|-----------|----------|--------|--------|
| 0 | Success | Shown to user in transcript (except UserPromptSubmit/SessionStart where it's added to context) | Not used |
| 2 | Blocking error | Not used | Fed back to Claude to process |
| Other | Non-blocking error | Not used | Shown to user, execution continues |

## JSON Output Reference

### PostToolUse

```json
{
  "decision": "block" | undefined,  // "block" prompts Claude with reason
  "reason": "Explanation",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Context for Claude"  // ← Key feature
  },
  "suppressOutput": true | false  // Hide from transcript
}
```

### PreToolUse

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow" | "deny" | "ask",
    "permissionDecisionReason": "Reason shown to user (allow/ask) or Claude (deny)"
  },
  "suppressOutput": true | false
}
```

Note: No `additionalContext` field available for PreToolUse!

## Why This Design?

1. **Non-blocking by default** - Developers should control when to fix issues
2. **Claude sees context** - PostToolUse uses `additionalContext` to inform Claude
3. **User visibility** - PreToolUse shows in transcript for user awareness
4. **Optional strictness** - Users can uncomment blocking mode if needed
5. **Clean workflow** - No noise when code is clean (`suppressOutput: true`)

## Customization

To enable blocking on commits:

1. Edit `scripts/pre-commit-check.sh`
2. Comment out lines 27-28 (non-blocking echo)
3. Uncomment lines 31-40 (blocking JSON output)
4. Restart Claude Code

This changes the behavior to:
- Issues found → Block commit, show to Claude
- No issues → Allow commit silently
