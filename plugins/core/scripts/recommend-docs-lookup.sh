#!/bin/bash

# Recommend documentation lookup when user mentions dependencies
# Triggered on UserPromptSubmit

# Read and validate stdin
INPUT=$(cat) || exit 1

# Extract user prompt
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty') || exit 1
if [[ -z "$PROMPT" ]]; then
  exit 0
fi

# Get current directory
CWD=$(echo "$INPUT" | jq -r '.cwd // empty') || exit 1
if [[ -z "$CWD" ]]; then
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

# Find project root
PROJECT_ROOT=$(find_mix_project_root "$CWD")

# If no project root found, exit silently (not an Elixir project)
if [ $? -ne 0 ]; then
  jq -n '{}'
  exit 0
fi

# Cache setup - use same directory as hex-docs-search skill
CACHE_DIR="$PROJECT_ROOT/.hex-docs"
CACHE_FILE="$CACHE_DIR/deps-cache.txt"
LOCK_FILE="$PROJECT_ROOT/mix.lock"

# Function to get dependencies using mix deps
get_deps_list() {
  cd "$PROJECT_ROOT" || exit 1
  # Parse mix deps output to get dependency names
  # Output format: "* dep_name version ..."
  mix deps 2>/dev/null | grep -E '^\*' | awk '{print $2}' | sort -u
}

# Check if cache is valid (exists and newer than mix.lock)
use_cache=false
if [[ -f "$CACHE_FILE" ]] && [[ -f "$LOCK_FILE" ]]; then
  # Compare modification times
  if [[ "$CACHE_FILE" -nt "$LOCK_FILE" ]]; then
    use_cache=true
  fi
fi

# Get or update dependency list
if [[ "$use_cache" == "true" ]]; then
  DEPS=$(cat "$CACHE_FILE")
else
  # Generate fresh list
  DEPS=$(get_deps_list)

  # Cache the result
  if [[ -n "$DEPS" ]]; then
    mkdir -p "$CACHE_DIR"
    echo "$DEPS" > "$CACHE_FILE"
  fi
fi

# If no deps found, exit silently
if [[ -z "$DEPS" ]]; then
  exit 0
fi

# Function to check if prompt contains a dependency (with variations)
matches_prompt() {
  local dep="$1"
  local prompt="$2"

  # Create variations:
  # 1. Original: ash_postgres
  # 2. Dash: ash-postgres
  # 3. Space: ash postgres
  # 4. Capitalized: Ash_postgres, AshPostgres
  local dep_dash="${dep//_/-}"
  local dep_space="${dep//_/ }"

  # Remove underscores for camelCase check: ash_postgres -> AshPostgres
  local dep_camel=""
  IFS='_' read -ra parts <<< "$dep"
  for part in "${parts[@]}"; do
    dep_camel+="$(echo "$part" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"
  done

  # Simple capitalized version: ecto -> Ecto
  local dep_cap="$(echo "$dep" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')"

  # Check for matches (case-insensitive word boundary)
  # Use \b for word boundary where applicable
  if echo "$prompt" | grep -qiE "\b($dep|$dep_dash|$dep_space|$dep_camel|$dep_cap)\b"; then
    return 0
  fi

  return 1
}

# Check each dependency against prompt
MATCHED_DEPS=()
while IFS= read -r dep; do
  if matches_prompt "$dep" "$PROMPT"; then
    MATCHED_DEPS+=("$dep")
  fi
done <<< "$DEPS"

# If matches found, recommend skill usage
if [ ${#MATCHED_DEPS[@]} -gt 0 ]; then
  # Build comma-separated list
  DEPS_LIST=$(printf ", %s" "${MATCHED_DEPS[@]}")
  DEPS_LIST=${DEPS_LIST:2}  # Remove leading comma and space

  # Create recommendation message
  CONTEXT="IMPORTANT: The user's prompt mentions these project dependencies: $DEPS_LIST. Consider using the hex-docs-search skill (for API documentation) or usage-rules skill (for best practices and patterns) to look up relevant information before implementing."

  # Output JSON with additionalContext
  jq -n \
    --arg context "$CONTEXT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": $context
      }
    }'
else
  # No matches - suppress output
  jq -n '{}'
fi

exit 0
