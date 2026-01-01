#!/usr/bin/env bash

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ -z "$COMMAND" ]] || [[ "$COMMAND" == "null" ]]; then
  exit 0
fi

if [[ -z "$CWD" ]] || [[ "$CWD" == "null" ]]; then
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

PROJECT_ROOT=$(find_mix_project_root "$GIT_DIR")

if [[ -z "$PROJECT_ROOT" ]]; then
  exit 0
fi

# Add version manager shims to PATH (mise/asdf support)
[[ -d "$HOME/.local/share/mise/shims" ]] && PATH="$HOME/.local/share/mise/shims:$PATH"
[[ -d "$HOME/.asdf/shims" ]] && PATH="$HOME/.asdf/shims:$PATH"

# Defer to precommit alias if it exists (Phoenix 1.8+ standard)
if cd "$PROJECT_ROOT" && mix help precommit >/dev/null 2>&1; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Check if Credo is a project dependency
if ! grep -qE '\{:credo' "$PROJECT_ROOT/mix.exs" 2>/dev/null; then
  exit 0
fi

CREDO_OUTPUT=$(cd "$PROJECT_ROOT" && mix credo --strict 2>&1)
CREDO_EXIT_CODE=$?

# Credo exit codes: 0 = no issues, >0 = issues found
if [ $CREDO_EXIT_CODE -ne 0 ]; then
  TOTAL_LINES=$(echo "$CREDO_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$CREDO_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix credo --strict' to see the full output."
  else
    OUTPUT="$CREDO_OUTPUT"
  fi

  REASON="Credo plugin found code quality issues:\n\n${OUTPUT}"

  jq -n \
    --arg reason "$REASON" \
    --arg msg "Commit blocked: Credo found code quality issues" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      },
      "systemMessage": $msg
    }'
  exit 0
else
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi
