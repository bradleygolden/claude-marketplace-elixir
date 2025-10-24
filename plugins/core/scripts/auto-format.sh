#!/bin/bash

# Auto-format Elixir files on edit

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

# If no project root found, exit silently (not an Elixir project)
if [ $? -ne 0 ]; then
  exit 0
fi

# Run mix format
cd "$PROJECT_ROOT" && mix format "$FILE_PATH"

exit 0
