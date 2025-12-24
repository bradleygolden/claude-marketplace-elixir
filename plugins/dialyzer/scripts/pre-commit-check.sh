#!/usr/bin/env bash

# Pre-commit validation for Dialyzer static type analysis
# Blocks commits if type issues are found (JSON permissionDecision: deny)
# Uses 120s timeout due to Dialyzer's analysis time

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

if ! grep -qE '\{:dialyxir' "$PROJECT_ROOT/mix.exs" 2>/dev/null; then
  exit 0
fi

DIALYZER_OUTPUT=$(cd "$PROJECT_ROOT" && mix dialyzer 2>&1)
DIALYZER_EXIT_CODE=$?

# Dialyzer exit code: 0 = no type errors, >0 = type errors found
if [ $DIALYZER_EXIT_CODE -ne 0 ]; then
  TOTAL_LINES=$(echo "$DIALYZER_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$DIALYZER_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix dialyzer' to see the full output."
  else
    OUTPUT="$DIALYZER_OUTPUT"
  fi

  REASON="Dialyzer plugin found type errors:\n\n${OUTPUT}"

  jq -n \
    --arg reason "$REASON" \
    --arg msg "Commit blocked: Dialyzer found type errors" \
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
  jq -n '{"suppressOutput": true}'
  exit 0
fi
