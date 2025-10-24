#!/bin/bash

# Pre-commit validation for mix_audit dependency security scanner
# Runs before git commits to check for vulnerable dependencies
# Blocks commits if vulnerabilities are found (exit 2)

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ -z "$COMMAND" ]] || [[ "$COMMAND" == "null" ]]; then
  exit 0
fi

if [[ -z "$CWD" ]] || [[ "$CWD" == "null" ]]; then
  exit 0
fi

# Only run audit check on git commits (not other bash commands)
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Function to find the Mix project root by traversing upward
find_mix_project_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_mix_project_root "$CWD")

if [[ -z "$PROJECT_ROOT" ]]; then
  exit 0
fi

if ! grep -qE '\{:mix_audit' "$PROJECT_ROOT/mix.exs" 2>/dev/null; then
  exit 0
fi

AUDIT_OUTPUT=$(cd "$PROJECT_ROOT" && mix deps.audit 2>&1)
AUDIT_EXIT_CODE=$?

# Block commit if vulnerabilities found
if [ $AUDIT_EXIT_CODE -ne 0 ]; then
  TOTAL_LINES=$(echo "$AUDIT_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$AUDIT_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix deps.audit' to see the full output."
  else
    OUTPUT="$AUDIT_OUTPUT"
  fi

  echo "$OUTPUT" >&2
  exit 2
fi

exit 0
