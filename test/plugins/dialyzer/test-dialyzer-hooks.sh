#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Dialyzer Plugin Hooks"
echo "================================"
echo ""

test_hook_json \
  "Pre-commit check: Blocks on Dialyzer type errors with structured JSON" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/dialyzer/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Dialyzer")) and .systemMessage != null'

test_hook_json \
  "Pre-commit check: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

test_hook \
  "Pre-commit check: Ignores non-commit git commands" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Ignores non-git commands" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test: Pre-commit check skips when Dialyxir not in dependencies
test_hook \
  "Pre-commit check: Skips when Dialyxir not in dependencies" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/fixtures/no-deps-project\"}" \
  0 \
  ""

# Test: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit check: Uses git -C directory instead of CWD" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/dialyzer/precommit-test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Dialyzer"))'

# Test: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit check: Falls back to CWD when -C path is invalid" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/dialyzer/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

print_summary
