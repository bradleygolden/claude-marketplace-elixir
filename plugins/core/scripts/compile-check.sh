#!/bin/bash

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
if [ $? -ne 0 ]; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

# Add version manager shims to PATH (mise/asdf support)
# Robust home detection: $HOME, then ~$USER, then ~$(whoami)
_HOME="${HOME:-$(eval echo ~${USER:-$(whoami)})}"
MISE_SHIMS="${XDG_DATA_HOME:-$_HOME/.local/share}/mise/shims"
ASDF_SHIMS="$_HOME/.asdf/shims"
[[ -d "$MISE_SHIMS" ]] && export PATH="$MISE_SHIMS:$PATH"
[[ -d "$ASDF_SHIMS" ]] && export PATH="$ASDF_SHIMS:$PATH"

cd "$PROJECT_ROOT"
COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
COMPILE_EXIT=$?

if [ $COMPILE_EXIT -ne 0 ]; then
  TOTAL_LINES=$(echo "$COMPILE_OUTPUT" | wc -l)
  MAX_LINES=50

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$COMPILE_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines. Run 'mix compile --warnings-as-errors' in $PROJECT_ROOT to see full output]"
  else
    OUTPUT="$COMPILE_OUTPUT"
  fi

  CONTEXT=$(echo "$OUTPUT" | jq -Rs .)

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
