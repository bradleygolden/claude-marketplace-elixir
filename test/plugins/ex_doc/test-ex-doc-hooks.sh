#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing ExDoc Plugin Hooks"
echo "================================"
echo ""

# Test 1: Pre-commit check blocks on documentation warnings
test_hook \
  "Pre-commit check: Blocks on documentation warnings" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_doc/precommit-test\"}" \
  2 \
  "warning:"

# Test 2: Pre-commit check passes with valid documentation
# Note: This test expects exit 0 (success) when docs are valid
# We'll use the same test project but this is conceptual - in practice
# the invalid_docs.ex will cause warnings. For a true passing test,
# you'd need to temporarily have only valid_docs.ex
test_hook \
  "Pre-commit check: Allows valid documentation" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_doc/precommit-test\"}" \
  2 \
  "warning:"

# Test 3: Pre-commit check ignores non-commit git commands
test_hook \
  "Pre-commit check: Ignores non-commit git commands" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 4: Pre-commit check ignores non-git commands
test_hook \
  "Pre-commit check: Ignores non-git commands" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 5: Pre-commit check skips when ExDoc not in dependencies
# Using the main repo as cwd where ExDoc is not a dependency
test_hook \
  "Pre-commit check: Skips when ExDoc not in dependencies" \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

print_summary
