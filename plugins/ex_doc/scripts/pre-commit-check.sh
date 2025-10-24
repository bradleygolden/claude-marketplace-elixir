#!/bin/bash
set -e

# ExDoc Pre-Commit Check
# Validates documentation quality before git commits using mix docs --warnings-as-errors

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ "$COMMAND" == "null" ]] || [[ -z "$COMMAND" ]]; then
  exit 0
fi

if [[ "$CWD" == "null" ]] || [[ -z "$CWD" ]]; then
  exit 0
fi

# Only run on git commit commands
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Find Mix project root by traversing upward from current working directory
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

set +e  # Temporarily disable exit on error
PROJECT_ROOT=$(find_mix_project_root "$CWD")
PROJECT_EXIT=$?
set -e  # Re-enable exit on error

# If no project root found, exit silently (not an Elixir project)
if [ $PROJECT_EXIT -ne 0 ]; then
  exit 0
fi

cd "$PROJECT_ROOT"

if ! grep -qE '\{:ex_doc' mix.exs 2>/dev/null; then
  exit 0
fi

# Run documentation validation
set +e
DOCS_OUTPUT=$(mix docs --warnings-as-errors 2>&1)
DOCS_EXIT_CODE=$?
set -e

# Block commit if documentation validation failed
if [ $DOCS_EXIT_CODE -ne 0 ]; then
  # Truncate output if too long (similar to credo and dialyzer plugins)
  TOTAL_LINES=$(echo "$DOCS_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$DOCS_OUTPUT" | head -n $MAX_LINES)
    echo "$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix docs --warnings-as-errors' to see the full output." >&2
  else
    echo "$DOCS_OUTPUT" >&2
  fi

  exit 2  # Exit code 2 blocks the git commit
fi

exit 0
