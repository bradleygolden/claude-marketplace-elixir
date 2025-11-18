#!/bin/bash

INPUT=$(cat) || exit 1

FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path' 2>/dev/null) || exit 1

if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" == "null" ]]; then
  exit 0
fi

# Only process Elixir-related files (.ex, .exs, .heex, .leex)
if ! echo "$FILE_PATH" | grep -qE '\.(ex|exs|heex|leex)$'; then
  exit 0
fi

find_mix_project_root() {
  local dir=$(dirname "$1")
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

PROJECT_ROOT=$(find_mix_project_root "$FILE_PATH")

# If no project root found, exit silently
if [[ -z "$PROJECT_ROOT" ]]; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

if ! grep -qE '\{:sobelow' "$PROJECT_ROOT/mix.exs" 2>/dev/null; then
  jq -n '{
    "suppressOutput": true
  }'
  exit 0
fi

cd "$PROJECT_ROOT"

# Run Sobelow with --skip flag (respects .sobelow-skips and #sobelow_skip comments)
# Use --format json for structured output
CMD="mix sobelow --format json"
[[ -f .sobelow-skips ]] && CMD="$CMD --skip"

SOBELOW_OUTPUT=$($CMD 2>&1)
SOBELOW_EXIT_CODE=$?

# Check for findings by parsing JSON (extract only JSON part, skipping any warnings)
HAS_FINDINGS=false
JSON_OUTPUT=$(echo "$SOBELOW_OUTPUT" | sed -n '/{/,$ p')
if echo "$JSON_OUTPUT" | jq -e '.findings | (.high_confidence + .medium_confidence + .low_confidence) | length > 0' > /dev/null 2>&1; then
  HAS_FINDINGS=true
fi

if [ $SOBELOW_EXIT_CODE -ne 0 ] || [ "$HAS_FINDINGS" = true ]; then
  TOTAL_LINES=$(echo "$SOBELOW_OUTPUT" | wc -l)
  MAX_LINES=30

  if [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
    TRUNCATED_OUTPUT=$(echo "$SOBELOW_OUTPUT" | head -n $MAX_LINES)
    CONTEXT="Sobelow security analysis for $FILE_PATH:

$TRUNCATED_OUTPUT

[Output truncated: showing $MAX_LINES of $TOTAL_LINES lines]
Run 'mix sobelow' in $PROJECT_ROOT to see the full output.

To suppress false positives:
  • Add inline comment: # sobelow_skip [\"FindingType\"]
  • Mark all as skipped: mix sobelow --mark-skip-all
  • Mark specific as skipped: mix sobelow --ignore Type1,Type2 --mark-skip-all"
  else
    CONTEXT="Sobelow security analysis for $FILE_PATH:

$SOBELOW_OUTPUT

To suppress false positives:
  • Add inline comment: # sobelow_skip [\"FindingType\"]
  • Mark all as skipped: mix sobelow --mark-skip-all
  • Mark specific as skipped: mix sobelow --ignore Type1,Type2 --mark-skip-all"
  fi

  jq -n \
    --arg context "$CONTEXT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": $context
      }
    }'
else
  jq -n '{
    "suppressOutput": true
  }'
fi

exit 0
