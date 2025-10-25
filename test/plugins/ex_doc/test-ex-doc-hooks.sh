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

# Test 2: Pre-commit check ignores non-commit git commands
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

print_summary
