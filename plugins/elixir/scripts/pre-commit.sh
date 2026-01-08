#!/usr/bin/env bash
# Pre-commit hook: validate Elixir project before git commit

source "${CLAUDE_PLUGIN_ROOT}/lib/utils.sh"

# Parse input
INPUT=$(cat) || exit 0
COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 0
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 0

# Validate input
[[ "$COMMAND" == "null" ]] || [[ -z "$COMMAND" ]] && exit 0
[[ "$CWD" == "null" ]] || [[ -z "$CWD" ]] && exit 0

# Only run on git commit commands
is_git_commit "$COMMAND" || exit 0

# Extract git directory (handles git -C flag)
GIT_DIR=$(extract_git_dir "$COMMAND" "$CWD")

# Find project root
PROJECT_ROOT=$(find_mix_project_root "$GIT_DIR") || exit 0

# Setup environment
setup_version_managers
cd "$PROJECT_ROOT" || exit 0

#------------------------------------------------------------------------------
# Defer to precommit alias if it exists (Phoenix 1.8+ standard)
#------------------------------------------------------------------------------
if has_precommit_alias; then
  PRECOMMIT_OUTPUT=$(mix precommit 2>&1)
  PRECOMMIT_EXIT=$?

  if [ $PRECOMMIT_EXIT -ne 0 ]; then
    PRECOMMIT_OUTPUT=$(truncate_output "$PRECOMMIT_OUTPUT" 50)
    output_deny "Precommit failed:\n\n${PRECOMMIT_OUTPUT}" "Commit blocked: mix precommit failed"
  else
    output_suppress
  fi
  exit 0
fi

# Collect all failures
FAILURES=""

#------------------------------------------------------------------------------
# 1. Core checks (format, compile, deps)
#------------------------------------------------------------------------------
FORMAT_OUTPUT=$(mix format --check-formatted 2>&1)
if [ $? -ne 0 ]; then
  FAILURES="${FAILURES}[FORMAT] Code is not formatted.\nRun 'mix format' to fix.\n\n"
fi

COMPILE_OUTPUT=$(mix compile --warnings-as-errors 2>&1)
if [ $? -ne 0 ]; then
  COMPILE_OUTPUT=$(truncate_output "$COMPILE_OUTPUT" 30)
  FAILURES="${FAILURES}[COMPILE]\n${COMPILE_OUTPUT}\n\n"
fi

DEPS_OUTPUT=$(mix deps.unlock --check-unused 2>&1)
if [ $? -ne 0 ]; then
  FAILURES="${FAILURES}[DEPS] Unused dependencies found.\nRun 'mix deps.unlock --unused' to fix.\n\n"
fi

#------------------------------------------------------------------------------
# 2. Credo (if dependency)
#------------------------------------------------------------------------------
if has_dependency "credo"; then
  CREDO_OUTPUT=$(mix credo --strict 2>&1)
  if [ $? -ne 0 ]; then
    CREDO_OUTPUT=$(truncate_output "$CREDO_OUTPUT" 30)
    FAILURES="${FAILURES}[CREDO]\n${CREDO_OUTPUT}\n\n"
  fi
fi

#------------------------------------------------------------------------------
# 3. Ash codegen (if dependency)
#------------------------------------------------------------------------------
if has_dependency "ash"; then
  ASH_OUTPUT=$(mix ash.codegen --check 2>&1)
  if [ $? -ne 0 ]; then
    ASH_OUTPUT=$(truncate_output "$ASH_OUTPUT" 30)
    FAILURES="${FAILURES}[ASH CODEGEN]\nRun 'mix ash.codegen' to update generated code.\n${ASH_OUTPUT}\n\n"
  fi
fi

#------------------------------------------------------------------------------
# 4. Dialyzer (if dependency) - can be slow
#------------------------------------------------------------------------------
if has_dependency "dialyxir"; then
  DIALYZER_OUTPUT=$(mix dialyzer 2>&1)
  if [ $? -ne 0 ]; then
    DIALYZER_OUTPUT=$(truncate_output "$DIALYZER_OUTPUT" 30)
    FAILURES="${FAILURES}[DIALYZER]\n${DIALYZER_OUTPUT}\n\n"
  fi
fi

#------------------------------------------------------------------------------
# 5. ExDoc (if dependency) - uses locking to prevent race conditions
#------------------------------------------------------------------------------
if has_dependency "ex_doc"; then
  if acquire_lock "mix_docs" 60; then
    DOCS_OUTPUT=$(mix docs --warnings-as-errors 2>&1)
    if [ $? -ne 0 ]; then
      DOCS_OUTPUT=$(truncate_output "$DOCS_OUTPUT" 30)
      FAILURES="${FAILURES}[EXDOC]\n${DOCS_OUTPUT}\n\n"
    fi
  fi
fi

#------------------------------------------------------------------------------
# 6. ExUnit tests (if test/ exists)
#------------------------------------------------------------------------------
if has_tests; then
  TEST_OUTPUT=$(mix test --stale 2>&1)
  if [ $? -ne 0 ]; then
    TEST_OUTPUT=$(truncate_output "$TEST_OUTPUT" 30)
    FAILURES="${FAILURES}[TESTS]\n${TEST_OUTPUT}\n\n"
  fi
fi

#------------------------------------------------------------------------------
# 7. Mix Audit (if dependency)
#------------------------------------------------------------------------------
if has_dependency "mix_audit"; then
  AUDIT_OUTPUT=$(mix deps.audit 2>&1)
  if [ $? -ne 0 ]; then
    AUDIT_OUTPUT=$(truncate_output "$AUDIT_OUTPUT" 30)
    FAILURES="${FAILURES}[SECURITY AUDIT]\n${AUDIT_OUTPUT}\n\n"
  fi
fi

#------------------------------------------------------------------------------
# 8. Sobelow (if dependency)
#------------------------------------------------------------------------------
if has_dependency "sobelow"; then
  SOBELOW_OUTPUT=$(mix sobelow --format json --skip 2>&1)
  SOBELOW_JSON=$(echo "$SOBELOW_OUTPUT" | sed -n '/^{/,/^}/p' | head -1)

  if [ -n "$SOBELOW_JSON" ]; then
    HIGH=$(echo "$SOBELOW_JSON" | jq -r '.findings.high_confidence | length' 2>/dev/null || echo "0")
    MEDIUM=$(echo "$SOBELOW_JSON" | jq -r '.findings.medium_confidence | length' 2>/dev/null || echo "0")

    if [ "$HIGH" -gt 0 ] || [ "$MEDIUM" -gt 0 ]; then
      FAILURES="${FAILURES}[SOBELOW]\nSecurity issues found: ${HIGH} high, ${MEDIUM} medium confidence.\nRun 'mix sobelow' for details.\n\n"
    fi
  fi
fi

#------------------------------------------------------------------------------
# Output results
#------------------------------------------------------------------------------
if [ -n "$FAILURES" ]; then
  output_deny "Pre-commit validation failed:\n\n${FAILURES}Fix these issues before committing." "Commit blocked: validation failed"
else
  output_suppress
fi

exit 0
