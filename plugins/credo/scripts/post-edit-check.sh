#!/bin/bash

INPUT=$(cat) || exit 1

# Validate JSON and extract file_path with error handling
FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path' 2>/dev/null) || exit 1

# Validate extracted value is not null
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" == "null" ]]; then
  exit 0
fi

if ! echo "$FILE_PATH" | grep -qE '\.(ex|exs)$'; then
  exit 0
fi

# Find Mix project root by traversing upward from file directory
find_mix_project_root() {
  local dir=$(dirname "$1")
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_mix_project_root "$FILE_PATH")

# If no project root found, exit silently
if [[ -z "$PROJECT_ROOT" ]]; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

CREDO_OUTPUT=$(cd "$PROJECT_ROOT" && mix credo "$FILE_PATH" 2>&1)
CREDO_EXIT_CODE=$?

if [ $CREDO_EXIT_CODE -ne 0 ] || echo "$CREDO_OUTPUT" | grep -qE '(issues|warnings|errors)'; then
  TOTAL_LINES=$(echo "$CREDO_OUTPUT" | wc -l)
  MAX_LINES=30

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

  jq -n \
    --arg context "$CONTEXT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": $context
      }
    }'
else
  jq -n '{
    "suppressOutput": true
  }'
fi

exit 0
