#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$REPO_ROOT/test/test-hook.sh"

echo "Testing Sobelow Plugin Hooks"
echo "========================================"

test_hook_json \
  "Post-edit check: Detects security violations" \
  "plugins/sobelow/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/sobelow/postedit-test/lib/vulnerable_code.ex\"},\"cwd\":\"$REPO_ROOT/test/plugins/sobelow/postedit-test\"}" \
  0 \
  ".hookSpecificOutput | has(\"additionalContext\")"

test_hook_json \
  "Post-edit check: Works on .exs files" \
  "plugins/sobelow/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/sobelow/postedit-test/test/test_helper.exs\"},\"cwd\":\"$REPO_ROOT/test/plugins/sobelow/postedit-test\"}" \
  0 \
  ".hookSpecificOutput | has(\"hookEventName\")"

test_hook \
  "Post-edit check: Ignores non-Elixir files" \
  "plugins/sobelow/scripts/post-edit-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

test_hook_json \
  "Pre-commit check: Blocks on security violations with structured JSON" \
  "plugins/sobelow/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/sobelow/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Sobelow")) and .systemMessage != null'

test_hook \
  "Pre-commit check: Ignores non-commit git commands" \
  "plugins/sobelow/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Ignores non-git commands" \
  "plugins/sobelow/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

echo "========================================"
print_summary
