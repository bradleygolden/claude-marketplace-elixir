#!/usr/bin/env bash

# Test suite for mix_audit plugin hooks
# Tests the pre-commit hook validation logic

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing mix_audit Plugin Hooks"
echo "================================"
echo ""

test_hook \
  "Pre-commit check: Ignores non-commit git commands (git status)" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Ignores non-git commands (npm install)" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Ignores non-Elixir projects" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Skips when mix_audit not in dependencies" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/mix_audit/no-audit-test\"}" \
  0 \
  ""

echo -e "${YELLOW}[TEST]${NC} Pre-commit check: Attempts to run mix deps.audit when mix_audit present"
HOOK_OUTPUT=$(echo "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/mix_audit/precommit-test\"}" | \
  bash "$REPO_ROOT/plugins/mix_audit/scripts/pre-commit-check.sh" 2>&1) || EXIT_CODE=$?
EXIT_CODE=${EXIT_CODE:-0}

# Check that it didn't skip (exit 0 with no output would mean it skipped)
# The hook should either:
# - Exit 0 if no vulnerabilities (clean audit)
# - Exit 2 if vulnerabilities found (blocking)
# - Exit with error if mix_audit not installed (which is expected in test env)
if [ "$EXIT_CODE" -eq 0 ] && [ -z "$HOOK_OUTPUT" ]; then
  echo -e "  ${RED}❌ FAIL${NC}: Hook skipped when it should have run"
  TESTS_FAILED=$((TESTS_FAILED + 1))
else
  echo -e "  ${GREEN}✅ PASS${NC}: Hook attempted to execute mix deps.audit"
  TESTS_PASSED=$((TESTS_PASSED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

print_summary
