#!/bin/bash

# Post-edit validation for Ash code generation
# Runs after editing .ex/.exs files to detect when ash.codegen is needed
# Provides informational context to Claude (non-blocking)

# Read and validate stdin
INPUT=$(cat) || exit 1

FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path' 2>/dev/null) || exit 1

if [[ "$FILE_PATH" == "null" ]] || [[ -z "$FILE_PATH" ]]; then
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

# If no project root found, exit silently with suppressOutput
if [[ -z "$PROJECT_ROOT" ]]; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

cd "$PROJECT_ROOT"

if ! grep -qE '\{:ash' mix.exs 2>/dev/null; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

CODEGEN_OUTPUT=$(mix ash.codegen --check 2>&1)
CODEGEN_EXIT=$?

if [ $CODEGEN_EXIT -ne 0 ]; then
  TOTAL_LINES=$(echo "$CODEGEN_OUTPUT" | wc -l)
  MAX_LINES=50

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$CODEGEN_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines. Run 'mix ash.codegen --check' in $PROJECT_ROOT to see full output]"
  else
    OUTPUT="$CODEGEN_OUTPUT"
  fi

  # Output JSON with additionalContext
  jq -n --arg context "$OUTPUT" '{
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
