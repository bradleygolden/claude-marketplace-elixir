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

if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Check if any Elixir-related files are staged
STAGED_FILES=$(cd "$CWD" && git diff --cached --name-only 2>/dev/null)
if ! echo "$STAGED_FILES" | grep -qE '\.(ex|exs|heex|leex)$'; then
  # No Elixir files staged, skip validation
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

# Check .claude-elixir.config for ignore patterns
find_repo_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/.git" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

REPO_ROOT=$(find_repo_root "$PROJECT_ROOT")
if [[ -n "$REPO_ROOT" ]] && [[ -f "$REPO_ROOT/.claude-elixir.config" ]]; then
  while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    # Skip comments and empty lines
    [[ "$pattern" =~ ^[[:space:]]*# ]] || [[ -z "${pattern// }" ]] && continue

    # Convert glob pattern to regex and check if PROJECT_ROOT matches
    regex_pattern=$(echo "$pattern" | sed 's|/\*\*/|/.*|g' | sed 's|\*|[^/]*|g')
    if echo "$PROJECT_ROOT" | grep -qE "$regex_pattern"; then
      exit 0
    fi
  done < "$REPO_ROOT/.claude-elixir.config"
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
