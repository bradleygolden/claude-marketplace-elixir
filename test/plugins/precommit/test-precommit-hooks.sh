#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Precommit Plugin Hooks"
echo "================================"
echo ""

# Test 1: Pre-commit hook blocks when precommit fails with structured JSON
test_hook_json \
  "Pre-commit: Blocks commits when mix precommit fails with structured JSON" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-fail\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Precommit")) and .systemMessage != null'

# Test 2: Pre-commit hook allows commits when precommit passes
test_hook_json \
  "Pre-commit: Allows commits when mix precommit passes" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 3: Pre-commit hook skips when no precommit alias exists
test_hook_json \
  "Pre-commit: Skips when no precommit alias in mix.exs" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/no-precommit-alias\"}" \
  0 \
  ".suppressOutput == true"

# Test 4: Pre-commit hook ignores non-commit git commands
test_hook \
  "Pre-commit: Ignores non-commit git commands" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ""

# Test 5: Pre-commit hook ignores non-git commands
test_hook \
  "Pre-commit: Ignores non-git commands" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"ls -la\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ""

# Test 6: Pre-commit hook skips non-Elixir projects
test_hook_json \
  "Pre-commit: Skips non-Elixir projects" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"/tmp\"}" \
  0 \
  ".suppressOutput == true"

# Test 7: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit: Uses git -C directory instead of CWD" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/precommit/precommit-test-pass commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ".suppressOutput == true"

# Test 8: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit: Falls back to CWD when -C path is invalid" \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

print_summary
