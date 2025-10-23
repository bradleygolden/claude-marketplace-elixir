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
  # Count total lines
  TOTAL_LINES=$(echo "$CREDO_OUTPUT" | wc -l)
  MAX_LINES=30

  # Truncate output if needed
  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$CREDO_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix credo --strict' to see the full output."
  else
    OUTPUT="$CREDO_OUTPUT"
  fi

  # For now, just inform without blocking - show output in transcript
  echo "$OUTPUT"
  exit 0

  # To block on issues and inform Claude, uncomment this instead:
  # jq -n \
  #   --arg reason "Credo found code quality issues that should be addressed before committing:
  #
  #$OUTPUT" \
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
