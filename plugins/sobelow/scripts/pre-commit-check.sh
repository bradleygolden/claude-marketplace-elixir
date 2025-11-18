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

if ! grep -qE '\{:sobelow' "$PROJECT_ROOT/mix.exs" 2>/dev/null; then
  exit 0
fi

cd "$PROJECT_ROOT"

# Run Sobelow with --skip flag (respects .sobelow-skips and #sobelow_skip comments)
# Note: We don't use --exit flag - threshold configuration is delegated to .sobelow-conf
# The hook blocks if ANY findings are reported (user controls what's reported via config)
CMD="mix sobelow --format json"
[[ -f .sobelow-skips ]] && CMD="$CMD --skip"

SOBELOW_OUTPUT=$($CMD 2>&1)
SOBELOW_EXIT_CODE=$?

# Check if there are any findings by parsing JSON output
# Extract JSON from output (Sobelow may emit warnings before JSON)
JSON_OUTPUT=$(echo "$SOBELOW_OUTPUT" | sed -n '/{/,$ p')
HAS_FINDINGS=false
if echo "$JSON_OUTPUT" | jq -e '.findings | (.high_confidence + .medium_confidence + .low_confidence) | length > 0' > /dev/null 2>&1; then
  HAS_FINDINGS=true
fi

if [ "$HAS_FINDINGS" = true ]; then
  TOTAL_LINES=$(echo "$SOBELOW_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$SOBELOW_OUTPUT" | head -n $MAX_LINES)
    OUTPUT="$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix sobelow' in $PROJECT_ROOT to see the full output.

WARNING: Sobelow found security issues. Options:
  1. Fix the issues (recommended)
  2. Mark false positives: mix sobelow --mark-skip-all
  3. Skip specific types: mix sobelow --ignore Type1,Type2 --mark-skip-all
  4. Adjust threshold: Create .sobelow-conf with --threshold flag"
  else
    OUTPUT="$SOBELOW_OUTPUT

WARNING: Sobelow found security issues. Options:
  1. Fix the issues (recommended)
  2. Mark false positives: mix sobelow --mark-skip-all
  3. Skip specific types: mix sobelow --ignore Type1,Type2 --mark-skip-all
  4. Adjust threshold: Create .sobelow-conf with --threshold flag"
  fi

  REASON="Sobelow plugin found security issues:\n\n${OUTPUT}"

  jq -n \
    --arg reason "$REASON" \
    --arg msg "Commit blocked: Sobelow found security issues" \
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
