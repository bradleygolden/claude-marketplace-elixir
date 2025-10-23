#!/bin/bash
# PreToolUse hook for credo - informs Claude via context only for critical issues

# Read input JSON from stdin
INPUT=$(cat)

# Extract command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Only process git commit commands
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Run credo in strict mode
CREDO_OUTPUT=$(mix credo --strict 2>&1)
CREDO_EXIT_CODE=$?

# Check for critical issues (consistency, readability issues that should block)
# Credo exit codes: 0 = no issues, >0 = issues found
if [ $CREDO_EXIT_CODE -ne 0 ]; then
  # Extract issue count and summary
  ISSUE_COUNT=$(echo "$CREDO_OUTPUT" | grep -E 'found.*issue' | head -1)

  # For now, just inform without blocking - show output in transcript
  # If you want to block on critical issues, uncomment below and use exit 2
  echo "$CREDO_OUTPUT" | head -50
  exit 0

  # To block on issues and inform Claude, uncomment this instead:
  # jq -n \
  #   --arg reason "Credo found code quality issues that should be addressed before committing:\n\n$(echo "$CREDO_OUTPUT" | head -50)" \
  #   '{
  #     "hookSpecificOutput": {
  #       "hookEventName": "PreToolUse",
  #       "permissionDecision": "deny",
  #       "permissionDecisionReason": $reason
  #     }
  #   }'
  # exit 0
else
  # No issues, allow silently
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi
