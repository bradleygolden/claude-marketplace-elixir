#!/bin/bash

# Pre-commit test validation for ExUnit
# Runs stale tests (tests for changed modules) before git commits
# Blocks commits if tests fail

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ "$COMMAND" == "null" ]] || [[ -z "$COMMAND" ]]; then
  exit 0
fi

if [[ "$CWD" == "null" ]] || [[ -z "$CWD" ]]; then
  exit 0
fi

if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Find Mix project root by traversing upward from CWD
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
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

if [ ! -d "$PROJECT_ROOT/test" ]; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

cd "$PROJECT_ROOT"

# Run stale tests (only tests for changed modules) - key to performance
TEST_OUTPUT=$(mix test --stale 2>&1)
TEST_EXIT=$?

if [ $TEST_EXIT -eq 0 ]; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

TOTAL_LINES=$(echo "$TEST_OUTPUT" | wc -l)
MAX_LINES=30

if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
  TRUNCATED_OUTPUT=$(echo "$TEST_OUTPUT" | head -n $MAX_LINES)
  FINAL_OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines. Run 'mix test --stale' in $PROJECT_ROOT to see full output]"
else
  FINAL_OUTPUT="$TEST_OUTPUT"
fi

# Block commit and send output to stderr (matches core plugin pattern)
echo "$FINAL_OUTPUT" >&2
exit 2
