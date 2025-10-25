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

PROJECT_ROOT=$(find_mix_project_root "$CWD")

if [[ -z "$PROJECT_ROOT" ]]; then
  exit 0
fi

cd "$PROJECT_ROOT"

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
