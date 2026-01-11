#!/usr/bin/env bash
# Post-edit hook: format, compile, and analyze Elixir files

source "${CLAUDE_PLUGIN_ROOT}/lib/utils.sh"

INPUT=$(cat) || exit 0
FILE_PATH=$(echo "$INPUT" | jq -e -r '.tool_input.file_path // .tool_input.path' 2>/dev/null) || exit 0

[[ "$FILE_PATH" == "null" ]] || [[ -z "$FILE_PATH" ]] && exit 0
is_elixir_file "$FILE_PATH" || exit 0

PROJECT_ROOT=$(find_mix_project_root "$(dirname "$FILE_PATH")") || exit 0

setup_version_managers
cd "$PROJECT_ROOT" || exit 0

ISSUES=""

# 1. Hex audit (only when mix.exs is edited - must run before format/compile)
if [[ "$FILE_PATH" == *"mix.exs"* ]]; then
  HEX_AUDIT_OUTPUT=$(mix hex.audit 2>&1)
  if [ $? -ne 0 ]; then
    HEX_AUDIT_OUTPUT=$(truncate_output "$HEX_AUDIT_OUTPUT" 20)
    ISSUES="${ISSUES}[HEX AUDIT] Retired dependencies found:\n${HEX_AUDIT_OUTPUT}\n\n"
  fi
fi

# 2. Format (always)
mix format "$FILE_PATH" 2>/dev/null

# 3. Compile check (always)
COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
COMPILE_EXIT=$?

if [ $COMPILE_EXIT -ne 0 ]; then
  COMPILE_OUTPUT=$(truncate_output "$COMPILE_OUTPUT" 50)
  ISSUES="${ISSUES}[COMPILE ERROR]\n${COMPILE_OUTPUT}\n\n"
fi

# 4. Credo (if dependency)
if has_dependency "credo"; then
  CREDO_OUTPUT=$(mix credo suggest "$FILE_PATH" --format oneline 2>&1)
  CREDO_EXIT=$?

  if [ $CREDO_EXIT -ne 0 ] && echo "$CREDO_OUTPUT" | grep -qE '\[(F|W|C|R)\]'; then
    CREDO_OUTPUT=$(truncate_output "$CREDO_OUTPUT" 30)
    ISSUES="${ISSUES}[CREDO]\n${CREDO_OUTPUT}\n\n"
  fi
fi

# 5. Ash codegen check (if dependency)
if has_dependency "ash"; then
  ASH_OUTPUT=$(mix ash.codegen --check 2>&1)
  ASH_EXIT=$?

  if [ $ASH_EXIT -ne 0 ]; then
    ASH_OUTPUT=$(truncate_output "$ASH_OUTPUT" 30)
    ISSUES="${ISSUES}[ASH CODEGEN]\nCode generation needed. Run 'mix ash.codegen' to update.\n${ASH_OUTPUT}\n\n"
  fi
fi

# 6. Sobelow security check (if dependency)
if has_dependency "sobelow"; then
  SOBELOW_OUTPUT=$(mix sobelow --format json --skip 2>&1)
  SOBELOW_JSON=$(echo "$SOBELOW_OUTPUT" | sed -n '/^{/,/^}/p' | tr '\n' ' ')

  if [ -n "$SOBELOW_JSON" ]; then
    HIGH=$(echo "$SOBELOW_JSON" | jq -r '.findings.high_confidence | length' 2>/dev/null || echo "0")
    MEDIUM=$(echo "$SOBELOW_JSON" | jq -r '.findings.medium_confidence | length' 2>/dev/null || echo "0")
    LOW=$(echo "$SOBELOW_JSON" | jq -r '.findings.low_confidence | length' 2>/dev/null || echo "0")

    if [ "$HIGH" -gt 0 ] || [ "$MEDIUM" -gt 0 ]; then
      ISSUES="${ISSUES}[SOBELOW SECURITY]\nFound: ${HIGH} high, ${MEDIUM} medium, ${LOW} low confidence findings.\nRun 'mix sobelow' for details.\n\n"
    fi
  fi
fi

if [ -n "$ISSUES" ]; then
  output_context "$(echo -e "$ISSUES")"
else
  output_suppress
fi

exit 0
