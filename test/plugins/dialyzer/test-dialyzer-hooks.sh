#!/usr/bin/env bash

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Dialyzer Plugin Hooks"
echo "================================"
echo ""

test_hook \
  "Pre-commit check: Blocks on Dialyzer type errors" \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/dialyzer/precommit-test\"}" \
  2 \
  "dialyzer"

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

print_summary
