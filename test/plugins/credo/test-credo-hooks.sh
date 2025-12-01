#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Credo Plugin Hooks"
echo "================================"
echo ""

# Test 1: Post-edit check detects Credo issues
test_hook_json \
  "Post-edit check: Detects Credo violations" \
  "plugins/credo/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/credo/postedit-test/lib/code_with_credo_issues.ex\"},\"cwd\":\"$REPO_ROOT/test/plugins/credo/postedit-test\"}" \
  0 \
  ".hookSpecificOutput | has(\"additionalContext\")"

# Test 2: Post-edit check on .exs file
test_hook_json \
  "Post-edit check: Works on .exs files" \
  "plugins/credo/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/credo/postedit-test/test/test_helper.exs\"},\"cwd\":\"$REPO_ROOT/test/plugins/credo/postedit-test\"}" \
  0 \
  ".hookSpecificOutput | has(\"hookEventName\")"

# Test 3: Post-edit check ignores non-Elixir files
test_hook \
  "Post-edit check: Ignores non-Elixir files" \
  "plugins/credo/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 4: Pre-commit check blocks on Credo violations with structured JSON
test_hook_json \
  "Pre-commit check: Blocks on Credo violations with structured JSON" \
  "plugins/credo/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/credo/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Credo")) and .systemMessage != null'

# Test 5: Pre-commit check skips when precommit alias exists
test_hook_json \
  "Pre-commit check: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/credo/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 6: Pre-commit check ignores non-commit commands
test_hook \
  "Pre-commit check: Ignores non-commit git commands" \
  "plugins/credo/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 6: Pre-commit check ignores non-git commands
test_hook \
  "Pre-commit check: Ignores non-git commands" \
  "plugins/credo/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 7: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit check: Uses git -C directory instead of CWD" \
  "plugins/credo/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/credo/precommit-test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Credo"))'

# Test 8: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit check: Falls back to CWD when -C path is invalid" \
  "plugins/credo/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/credo/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

print_summary
