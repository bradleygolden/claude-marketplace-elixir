#!/usr/bin/env bash
# Shared utilities for Claude Code Elixir plugin
# Source: source "${CLAUDE_PLUGIN_ROOT}/lib/utils.sh"

#------------------------------------------------------------------------------
# Version Manager Setup
#------------------------------------------------------------------------------

setup_version_managers() {
  _HOME="${HOME:-$(eval echo ~${USER:-$(whoami)})}"
  MISE_SHIMS="${XDG_DATA_HOME:-$_HOME/.local/share}/mise/shims"
  ASDF_SHIMS="$_HOME/.asdf/shims"
  [[ -d "$MISE_SHIMS" ]] && export PATH="$MISE_SHIMS:$PATH"
  [[ -d "$ASDF_SHIMS" ]] && export PATH="$ASDF_SHIMS:$PATH"
}

#------------------------------------------------------------------------------
# Project Detection
#------------------------------------------------------------------------------

# Find Mix project root by traversing upward
# Usage: PROJECT_ROOT=$(find_mix_project_root "$DIR")
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

# Check if mix.exs has a dependency
# Usage: has_dependency "credo" && echo "yes"
has_dependency() {
  local dep_name="$1"
  grep -qE "\{:${dep_name}" "$PROJECT_ROOT/mix.exs" 2>/dev/null
}

# Check if project has precommit alias (Phoenix 1.8+ standard)
# Usage: has_precommit_alias && echo "yes"
has_precommit_alias() {
  mix help precommit >/dev/null 2>&1
}

# Check if test directory exists
# Usage: has_tests && echo "yes"
has_tests() {
  [[ -d "$PROJECT_ROOT/test" ]]
}

#------------------------------------------------------------------------------
# Input Parsing
#------------------------------------------------------------------------------

# Check if file is an Elixir file (.ex or .exs)
# Usage: is_elixir_file "$FILE_PATH" && echo "yes"
is_elixir_file() {
  echo "$1" | grep -qE '\.(ex|exs)$'
}

# Check if command is a git commit
# Usage: is_git_commit "$COMMAND" && echo "yes"
is_git_commit() {
  echo "$1" | grep -qE 'git\b.*\bcommit\b'
}

# Extract directory from git -C flag if present
# Usage: GIT_DIR=$(extract_git_dir "$COMMAND" "$CWD")
extract_git_dir() {
  local command="$1"
  local cwd="$2"
  local git_dir="$cwd"

  if echo "$command" | grep -qE 'git\s+-C\s+'; then
    git_dir=$(echo "$command" | sed -n 's/.*git[[:space:]]*-C[[:space:]]*\([^[:space:]]*\).*/\1/p')
    if [[ -z "$git_dir" ]] || [[ ! -d "$git_dir" ]]; then
      git_dir="$cwd"
    fi
  fi
  echo "$git_dir"
}

#------------------------------------------------------------------------------
# Cross-Process Locking
#------------------------------------------------------------------------------

# Acquire a project-scoped lock to prevent concurrent processes from racing
# Usage: acquire_lock "mix_docs" || exit 1
# Note: Sets up automatic cleanup via trap
acquire_lock() {
  local name="$1"
  local timeout="${2:-60}"
  local wait=0

  LOCK_DIR="/tmp/${name}_$(echo "$PROJECT_ROOT" | shasum -a 256 | cut -d' ' -f1).lock"

  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [ $wait -ge $timeout ]; then
      echo "ERROR: Timeout waiting for $name lock" >&2
      return 1
    fi
    sleep 1
    wait=$((wait + 1))
  done

  trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT
  return 0
}

#------------------------------------------------------------------------------
# Output Formatting
#------------------------------------------------------------------------------

# Truncate output to N lines
# Usage: OUTPUT=$(truncate_output "$OUTPUT" 30)
truncate_output() {
  local output="$1"
  local max_lines="${2:-30}"
  local total_lines

  total_lines=$(echo "$output" | wc -l | tr -d ' ')

  if [ "$total_lines" -gt "$max_lines" ]; then
    local truncated
    truncated=$(echo "$output" | head -n "$max_lines")
    echo "$truncated"
    echo ""
    echo "[Output truncated: showing $max_lines of $total_lines lines]"
  else
    echo "$output"
  fi
}

#------------------------------------------------------------------------------
# JSON Output Helpers
#------------------------------------------------------------------------------

# Output JSON to deny/block a PreToolUse hook
# Usage: output_deny "Reason message" "System message"
output_deny() {
  local reason="$1"
  local system_msg="${2:-Commit blocked}"

  jq -n \
    --arg reason "$reason" \
    --arg msg "$system_msg" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      },
      "systemMessage": $msg
    }'
}

# Output JSON with additionalContext for PostToolUse
# Usage: output_context "Context message"
output_context() {
  local context="$1"

  jq -n --arg context "$context" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $context
    }
  }'
}

# Output JSON to suppress output
# Usage: output_suppress
output_suppress() {
  jq -n '{"suppressOutput": true}'
}
