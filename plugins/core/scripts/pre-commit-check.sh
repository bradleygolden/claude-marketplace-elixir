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

cd "$PROJECT_ROOT"

# Defer to precommit alias if it exists (Phoenix 1.8+ standard)
if mix help precommit >/dev/null 2>&1; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

FORMAT_OUTPUT=$(mix format --check-formatted 2>&1)
FORMAT_EXIT=$?

COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
COMPILE_EXIT=$?

DEPS_OUTPUT=$(mix deps.unlock --check-unused 2>&1)
DEPS_EXIT=$?

if [ $FORMAT_EXIT -ne 0 ] || [ $COMPILE_EXIT -ne 0 ] || [ $DEPS_EXIT -ne 0 ]; then
  ERROR_MSG="Core plugin pre-commit validation failed:\n\n"

  if [ $FORMAT_EXIT -ne 0 ]; then
    ERROR_MSG="${ERROR_MSG}[ERROR] Format check failed:\n${FORMAT_OUTPUT}\n\n"
  fi

  if [ $COMPILE_EXIT -ne 0 ]; then
    ERROR_MSG="${ERROR_MSG}[ERROR] Compilation failed:\n${COMPILE_OUTPUT}\n\n"
  fi

  if [ $DEPS_EXIT -ne 0 ]; then
    ERROR_MSG="${ERROR_MSG}[ERROR] Unused dependencies check failed:\n${DEPS_OUTPUT}\n\n"
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
