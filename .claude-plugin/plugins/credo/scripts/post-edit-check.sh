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

# Run credo on the file
CREDO_OUTPUT=$(mix credo "$FILE_PATH" 2>&1 | head -50)

# Check if there are any issues
if echo "$CREDO_OUTPUT" | grep -qE '(issues|warnings|errors)'; then
  # Output JSON with additionalContext to inform Claude
  jq -n \
    --arg context "Credo analysis for $FILE_PATH:\n$CREDO_OUTPUT" \
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
