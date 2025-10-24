#!/bin/bash

# Check compilation after file edits

# Read and validate stdin
INPUT=$(cat) || exit 1

# Extract file_path with error handling
FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path' 2>/dev/null) || exit 1

# Validate extracted value is not null
if [[ "$FILE_PATH" == "null" ]] || [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only process .ex and .exs files
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

# Find project root
PROJECT_ROOT=$(find_mix_project_root "$FILE_PATH")

# If no project root found, exit silently with suppressOutput
if [ $? -ne 0 ]; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

# Run compilation
cd "$PROJECT_ROOT"
COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
COMPILE_EXIT=$?

# If compilation failed, send context to Claude
if [ $COMPILE_EXIT -ne 0 ]; then
  # Count output lines
  TOTAL_LINES=$(echo "$COMPILE_OUTPUT" | wc -l)
  MAX_LINES=50
  
  # Truncate if needed
  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$COMPILE_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines. Run 'mix compile --warnings-as-errors' in $PROJECT_ROOT to see full output]"
  else
    OUTPUT="$COMPILE_OUTPUT"
  fi
  
  # Escape for JSON
  CONTEXT=$(echo "$OUTPUT" | jq -Rs .)
  
  # Output JSON with additionalContext
  jq -n --arg ctx "$CONTEXT" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $ctx
    }
  }'
else
  # Compilation succeeded - suppress output
  jq -n '{
    "suppressOutput": true
  }'
fi

exit 0
