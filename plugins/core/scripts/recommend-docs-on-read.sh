#!/bin/bash

# Recommend documentation lookup when reading files with dependency module references
# Triggered on PostToolUse (Read)

# Read and validate stdin
INPUT=$(cat) || exit 1

# Extract file_path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty') || exit 1
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" == "null" ]]; then
  jq -n '{}'
  exit 0
fi

# Only process .ex and .exs files
if ! echo "$FILE_PATH" | grep -qE '\.(ex|exs)$'; then
  jq -n '{}'
  exit 0
fi

# Check if file exists
if [[ ! -f "$FILE_PATH" ]]; then
  jq -n '{}'
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
  jq -n '{}'
  exit 0
fi

# Cache setup - use same directory as other hooks
CACHE_DIR="$PROJECT_ROOT/.hex-docs"
CACHE_FILE="$CACHE_DIR/deps-cache.txt"
LOCK_FILE="$PROJECT_ROOT/mix.lock"

# Function to get dependencies using mix deps
get_deps_list() {
  cd "$PROJECT_ROOT" || exit 1
  mix deps 2>/dev/null | grep -E '^\*' | awk '{print $2}' | sort -u
}

# Check if cache is valid (exists and newer than mix.lock)
use_cache=false
if [[ -f "$CACHE_FILE" ]] && [[ -f "$LOCK_FILE" ]]; then
  if [[ "$CACHE_FILE" -nt "$LOCK_FILE" ]]; then
    use_cache=true
  fi
fi

# Get or update dependency list
if [[ "$use_cache" == "true" ]]; then
  DEPS=$(cat "$CACHE_FILE")
else
  DEPS=$(get_deps_list)
  if [[ -n "$DEPS" ]]; then
    mkdir -p "$CACHE_DIR"
    echo "$DEPS" > "$CACHE_FILE"
  fi
fi

# If no deps found, exit silently
if [[ -z "$DEPS" ]]; then
  jq -n '{}'
  exit 0
fi

# Extract module references from file
# Matches: alias Ecto.Query, import Phoenix.Controller, use Ash.Resource, direct calls like Jason.decode()
MODULES=$(
  {
    # From alias/import/use statements
    grep -oE '(alias|import|use)\s+[A-Z][a-zA-Z0-9.]*' "$FILE_PATH" 2>/dev/null | awk '{print $2}'
    # From direct module calls (capitalized identifier followed by dot)
    grep -oE '\b[A-Z][a-zA-Z0-9]*\.' "$FILE_PATH" 2>/dev/null | sed 's/\.$//'
  } | \
  # Extract first segment (top-level module name)
  awk -F. '{print $1}' | \
  # Convert to lowercase for matching
  tr '[:upper:]' '[:lower:]' | \
  # Remove duplicates
  sort -u
)

# If no modules found, exit silently
if [[ -z "$MODULES" ]]; then
  jq -n '{}'
  exit 0
fi

# Match modules against dependencies
MATCHED_DEPS=()
while IFS= read -r module; do
  # Skip if empty
  [[ -z "$module" ]] && continue

  # Check if module matches any dependency (case-insensitive)
  while IFS= read -r dep; do
    [[ -z "$dep" ]] && continue

    # Normalize dependency name for comparison
    dep_normalized=$(echo "$dep" | tr '[:upper:]' '[:lower:]' | tr '_' ' ')
    module_normalized=$(echo "$module" | tr '_' ' ')

    # Check for match
    if echo "$dep_normalized" | grep -qiE "\b$module_normalized\b"; then
      # Avoid duplicates
      if [[ ! " ${MATCHED_DEPS[@]} " =~ " ${dep} " ]]; then
        MATCHED_DEPS+=("$dep")
      fi
    fi
  done <<< "$DEPS"
done <<< "$MODULES"

# If matches found, recommend skill usage
if [ ${#MATCHED_DEPS[@]} -gt 0 ]; then
  # Build comma-separated list
  DEPS_LIST=$(printf ", %s" "${MATCHED_DEPS[@]}")
  DEPS_LIST=${DEPS_LIST:2}  # Remove leading comma and space

  # Create recommendation message
  CONTEXT="The file uses these project dependencies: $DEPS_LIST. Consider using the hex-docs-search skill (for API documentation) or usage-rules skill (for best practices) to look up relevant information."

  # Output JSON with additionalContext
  jq -n \
    --arg context "$CONTEXT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": $context
      }
    }'
else
  # No matches - suppress output
  jq -n '{}'
fi

exit 0
