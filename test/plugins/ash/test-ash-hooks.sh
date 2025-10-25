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

print_summary
