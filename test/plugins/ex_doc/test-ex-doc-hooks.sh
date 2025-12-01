#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing ExDoc Plugin Hooks"
echo "================================"
echo ""

# Test 1: Pre-commit check blocks on documentation warnings with structured JSON
test_hook_json \
  "Pre-commit check: Blocks on documentation warnings with structured JSON" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_doc/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("ExDoc")) and .systemMessage != null'

# Test 2: Pre-commit check skips when precommit alias exists
test_hook_json \
  "Pre-commit check: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 3: Pre-commit check ignores non-commit git commands
test_hook \
  "Pre-commit check: Ignores non-commit git commands" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 3: Pre-commit check ignores non-git commands
test_hook \
  "Pre-commit check: Ignores non-git commands" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 4: Pre-commit check skips when ExDoc not in dependencies
# Using the main repo as cwd where ExDoc is not a dependency
test_hook \
  "Pre-commit check: Skips when ExDoc not in dependencies" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 5: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit check: Uses git -C directory instead of CWD" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/ex_doc/precommit-test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("ExDoc"))'

# Test 6: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit check: Falls back to CWD when -C path is invalid" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_doc/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

print_summary
