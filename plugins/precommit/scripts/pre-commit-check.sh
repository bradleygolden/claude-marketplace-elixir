#!/usr/bin/env bash

# Pre-commit validation using Phoenix precommit alias
# Runs mix precommit before git commits if the alias exists in mix.exs

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
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Add version manager shims to PATH (mise/asdf support)
[[ -d "$HOME/.local/share/mise/shims" ]] && PATH="$HOME/.local/share/mise/shims:$PATH"
[[ -d "$HOME/.asdf/shims" ]] && PATH="$HOME/.asdf/shims:$PATH"

cd "$PROJECT_ROOT"

# Check if precommit alias exists using Mix (authoritative detection)
if ! mix help precommit >/dev/null 2>&1; then
  # No precommit alias - suppress output and let other plugins handle validation
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Run mix precommit
PRECOMMIT_OUTPUT=$(mix precommit 2>&1)
PRECOMMIT_EXIT=$?

# Success case - suppress output
if [ $PRECOMMIT_EXIT -eq 0 ]; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Failure case - truncate output and block commit
TOTAL_LINES=$(echo "$PRECOMMIT_OUTPUT" | wc -l)
MAX_LINES=50

if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
  TRUNCATED_OUTPUT=$(echo "$PRECOMMIT_OUTPUT" | head -n $MAX_LINES)
  FINAL_OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines. Run 'mix precommit' in $PROJECT_ROOT to see full output]"
else
  FINAL_OUTPUT="$PRECOMMIT_OUTPUT"
fi

ERROR_MSG="Precommit validation failed:\n\n${FINAL_OUTPUT}\n\nFix these issues before committing."

jq -n \
  --arg reason "$ERROR_MSG" \
  --arg msg "Commit blocked: mix precommit validation failed" \
  '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    },
    "systemMessage": $msg
  }'
exit 0
