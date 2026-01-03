#!/usr/bin/env bash

# Pre-commit validation for Ash code generation
# Blocks git commits if ash.codegen is out of sync with resource definitions

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

if ! grep -qE '\{:ash' mix.exs 2>/dev/null; then
  exit 0
fi

CODEGEN_OUTPUT=$(mix ash.codegen --check 2>&1)
CODEGEN_EXIT=$?

if [ $CODEGEN_EXIT -ne 0 ]; then
  REASON="Ash plugin detected code generation is out of sync:\n\n${CODEGEN_OUTPUT}\n\nRun 'mix ash.codegen' to update generated code."

  jq -n \
    --arg reason "$REASON" \
    --arg msg "Commit blocked: Ash code generation required" \
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
