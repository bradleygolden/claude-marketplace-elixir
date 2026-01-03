#!/usr/bin/env bash

# ExDoc Pre-Commit Check

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ "$COMMAND" == "null" ]] || [[ -z "$COMMAND" ]]; then
  exit 0
fi

if [[ "$CWD" == "null" ]] || [[ -z "$CWD" ]]; then
  exit 0
fi

if ! echo "$COMMAND" | grep -qE 'git\b.*\bcommit\b'; then
  exit 0
fi

# Extract directory from git -C flag if present, otherwise use CWD
GIT_DIR="$CWD"
if echo "$COMMAND" | grep -qE 'git\s+-C\s+'; then
  GIT_DIR=$(echo "$COMMAND" | sed -n 's/.*git[[:space:]]*-C[[:space:]]*\([^[:space:]]*\).*/\1/p')
  if [[ -z "$GIT_DIR" ]] || [[ ! -d "$GIT_DIR" ]]; then
    GIT_DIR="$CWD"
  fi
fi

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

PROJECT_ROOT=$(find_mix_project_root "$GIT_DIR")

if [[ -z "$PROJECT_ROOT" ]]; then
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

# Defer to precommit alias if it exists (Phoenix 1.8+ standard)
if mix help precommit >/dev/null 2>&1; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

if ! grep -qE '\{:ex_doc' mix.exs 2>/dev/null; then
  exit 0
fi

# Acquire lock to prevent concurrent mix docs processes from racing
# This prevents file conflicts when multiple hooks run in parallel
# Use /tmp for lock directory to avoid cluttering project directory
# Use mkdir for cross-platform atomic locking (works on both macOS and Linux)
LOCK_DIR="/tmp/mix_docs_$(echo "$PROJECT_ROOT" | shasum -a 256 | cut -d' ' -f1).lock"

# Try to acquire lock, wait up to 60 seconds if another process holds it
LOCK_TIMEOUT=60
LOCK_WAIT=0
while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  if [ $LOCK_WAIT -ge $LOCK_TIMEOUT ]; then
    echo "ERROR: Timeout waiting for documentation generation lock" >&2
    exit 1
  fi
  sleep 1
  LOCK_WAIT=$((LOCK_WAIT + 1))
done

trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

DOCS_OUTPUT=$(mix docs --warnings-as-errors 2>&1)
DOCS_EXIT_CODE=$?

if [ $DOCS_EXIT_CODE -ne 0 ]; then
  TOTAL_LINES=$(echo "$DOCS_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$DOCS_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix docs --warnings-as-errors' to see the full output."
  else
    OUTPUT="$DOCS_OUTPUT"
  fi

  REASON="ExDoc plugin found documentation warnings:\n\n${OUTPUT}"

  jq -n \
    --arg reason "$REASON" \
    --arg msg "Commit blocked: ExDoc found documentation warnings" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      },
      "systemMessage": $msg
    }'
  exit 0
fi

jq -n '{"suppressOutput": true}'
exit 0
