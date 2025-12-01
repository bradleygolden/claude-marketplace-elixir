#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Ash Plugin Hooks"
echo "================================"
echo ""
test_hook_json \
  "Post-edit check: Detects when codegen is needed" \
  "plugins/ash/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/ash/postedit_test/lib/postedit_test/accounts/user.ex\"},\"cwd\":\"$REPO_ROOT/test/plugins/ash/postedit_test\"}" \
  0 \
  ".hookSpecificOutput | has(\"additionalContext\")"
test_hook_json \
  "Post-edit check: Works on .exs files" \
  "plugins/ash/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/ash/postedit_test/test/test_helper.exs\"},\"cwd\":\"$REPO_ROOT/test/plugins/ash/postedit_test\"}" \
  0 \
  ".hookSpecificOutput | has(\"hookEventName\")"
test_hook \
  "Post-edit check: Ignores non-Elixir files" \
  "plugins/ash/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""
test_hook_json \
  "Pre-commit check: Blocks when codegen is needed with structured JSON" \
  "plugins/ash/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ash/precommit_test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Ash")) and .systemMessage != null'
test_hook_json \
  "Pre-commit check: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/ash/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"
test_hook \
  "Pre-commit check: Ignores non-commit git commands" \
  "plugins/ash/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""
test_hook \
  "Pre-commit check: Ignores non-git commands" \
  "plugins/ash/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit check: Uses git -C directory instead of CWD" \
  "plugins/ash/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/ash/precommit_test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Ash"))'

# Test: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit check: Falls back to CWD when -C path is invalid" \
  "plugins/ash/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ash/precommit_test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

print_summary
