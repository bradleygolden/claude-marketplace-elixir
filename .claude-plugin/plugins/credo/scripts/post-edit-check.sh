#!/bin/bash
# PostToolUse hook for credo - informs Claude via context

# Read input JSON from stdin
INPUT=$(cat)

# Extract file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path')

# Only process Elixir files
if ! echo "$FILE_PATH" | grep -qE '\.(ex|exs)$'; then
  exit 0
fi

# Run credo on the file and capture full output
CREDO_OUTPUT=$(mix credo "$FILE_PATH" 2>&1)
CREDO_EXIT_CODE=$?

# Check if there are any issues
if [ $CREDO_EXIT_CODE -ne 0 ] || echo "$CREDO_OUTPUT" | grep -qE '(issues|warnings|errors)'; then
  # Count total lines
  TOTAL_LINES=$(echo "$CREDO_OUTPUT" | wc -l)
  MAX_LINES=30

  # Truncate output if needed
  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$CREDO_OUTPUT" | head -n $MAX_LINES)
    CONTEXT="Credo analysis for $FILE_PATH:

$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix credo \"$FILE_PATH\"' to see the full output."
  else
    CONTEXT="Credo analysis for $FILE_PATH:

$CREDO_OUTPUT"
  fi

  # Output JSON with additionalContext to inform Claude
  jq -n \
    --arg context "$CONTEXT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": $context
      }
    }'
else
  # No issues, suppress output
  jq -n '{
    "suppressOutput": true
  }'
fi

exit 0
