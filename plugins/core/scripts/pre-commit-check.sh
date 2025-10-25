#!/usr/bin/env bash

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

if [ $? -ne 0 ]; then
  exit 0
fi

cd "$PROJECT_ROOT"

FORMAT_OUTPUT=$(mix format --check-formatted 2>&1)
FORMAT_EXIT=$?

COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
COMPILE_EXIT=$?

DEPS_OUTPUT=$(mix deps.unlock --check-unused 2>&1)
DEPS_EXIT=$?

if [ $FORMAT_EXIT -ne 0 ] || [ $COMPILE_EXIT -ne 0 ] || [ $DEPS_EXIT -ne 0 ]; then
  ERROR_MSG="Core plugin pre-commit validation failed:\n\n"

  if [ $FORMAT_EXIT -ne 0 ]; then
    ERROR_MSG="${ERROR_MSG}❌ Format check failed:\n${FORMAT_OUTPUT}\n\n"
  fi

  if [ $COMPILE_EXIT -ne 0 ]; then
    ERROR_MSG="${ERROR_MSG}❌ Compilation failed:\n${COMPILE_OUTPUT}\n\n"
  fi

  if [ $DEPS_EXIT -ne 0 ]; then
    ERROR_MSG="${ERROR_MSG}❌ Unused dependencies check failed:\n${DEPS_OUTPUT}\n\n"
  fi

  ERROR_MSG="${ERROR_MSG}Fix these issues before committing."

  jq -n \
    --arg reason "$ERROR_MSG" \
    --arg msg "Commit blocked: core validation checks failed" \
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
