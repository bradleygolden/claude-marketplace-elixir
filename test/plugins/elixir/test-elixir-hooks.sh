#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

export CLAUDE_PLUGIN_ROOT="$REPO_ROOT/plugins/elixir"

echo "Testing Elixir Plugin Hooks"
echo "================================"
echo ""

# Test 1: Post-edit hook on .ex file with compilation error provides context
test_hook_json \
  "Post-edit: Detects compilation errors" \
  "plugins/elixir/scripts/post-edit.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/elixir/postedit-test/lib/broken_code.ex\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/postedit-test\"}" \
  0 \
  ".hookSpecificOutput | has(\"additionalContext\")"

# Test 2: Post-edit hook ignores non-Elixir files
test_hook \
  "Post-edit: Ignores non-Elixir files" \
  "plugins/elixir/scripts/post-edit.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 3: Pre-commit validation blocks on unformatted/broken code
test_hook_json \
  "Pre-commit: Blocks on validation failures" \
  "plugins/elixir/scripts/pre-commit.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny"'

# Test 4: Pre-commit validation ignores non-commit commands
test_hook \
  "Pre-commit: Ignores non-commit git commands" \
  "plugins/elixir/scripts/pre-commit.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 5: Pre-commit validation ignores non-git commands
test_hook \
  "Pre-commit: Ignores non-git commands" \
  "plugins/elixir/scripts/pre-commit.sh" \
  "{\"tool_input\":{\"command\":\"ls -la\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 6: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit: Uses git -C directory instead of CWD" \
  "plugins/elixir/scripts/pre-commit.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/elixir/precommit-test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 7: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit: Falls back to CWD when -C path is invalid" \
  "plugins/elixir/scripts/pre-commit.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/elixir/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

# Test 8: Pre-commit skips when precommit alias exists
test_hook_json \
  "Pre-commit: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/elixir/scripts/pre-commit.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

print_summary
