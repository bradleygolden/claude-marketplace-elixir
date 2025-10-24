#!/bin/bash

# Pre-commit validation for Elixir projects

# Read and validate stdin
INPUT=$(cat) || exit 1

# Extract command and cwd with error handling
COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

# Validate extracted values are not null
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

# Find project root
PROJECT_ROOT=$(find_mix_project_root "$CWD")

# If no project root found, exit silently (not an Elixir project)
if [ $? -ne 0 ]; then
  exit 0
fi

# Change to project root
cd "$PROJECT_ROOT"

# Run validation checks
mix format --check-formatted 2>&1 >&2
FORMAT_EXIT=$?

mix compile --warnings-as-errors 2>&1 >&2
COMPILE_EXIT=$?

mix deps.unlock --check-unused 2>&1 >&2
DEPS_EXIT=$?

# If any check failed, block the commit
if [ $FORMAT_EXIT -ne 0 ] || [ $COMPILE_EXIT -ne 0 ] || [ $DEPS_EXIT -ne 0 ]; then
  exit 2
fi

# All checks passed
exit 0
