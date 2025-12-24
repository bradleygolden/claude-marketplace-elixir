#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing Core Plugin Hooks"
echo "================================"
echo ""

# Test 1: Auto-format hook on .ex file
test_hook \
  "Auto-format hook: Formats badly formatted .ex file" \
  "plugins/core/scripts/auto-format.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/autoformat-test/lib/badly_formatted.ex\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/autoformat-test\"}" \
  0 \
  ""

# Test 2: Auto-format hook on .exs file
test_hook \
  "Auto-format hook: Formats .exs files" \
  "plugins/core/scripts/auto-format.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/autoformat-test/test/test_helper.exs\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/autoformat-test\"}" \
  0 \
  ""

# Test 3: Auto-format hook ignores non-Elixir files
test_hook \
  "Auto-format hook: Ignores non-Elixir files" \
  "plugins/core/scripts/auto-format.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 4: Compile check on broken code provides context
test_hook_json \
  "Compile check: Detects compilation errors" \
  "plugins/core/scripts/compile-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/broken_code.ex\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/compile-test\"}" \
  0 \
  ".hookSpecificOutput | has(\"additionalContext\")"

# Test 5: Compile check on non-Elixir file is ignored
test_hook \
  "Compile check: Ignores non-Elixir files" \
  "plugins/core/scripts/compile-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 6: Pre-commit validation blocks on unformatted code with JSON
test_hook_json \
  "Pre-commit: Blocks on unformatted code with structured JSON" \
  "plugins/core/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Core plugin")) and .systemMessage != null'

# Test 7: Pre-commit validation shows compilation errors in permissionDecisionReason
test_hook_json \
  "Pre-commit: Shows compilation errors in structured output" \
  "plugins/core/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecisionReason | contains("Compilation failed")'

# Test 8: Pre-commit validation skips when precommit alias exists
test_hook_json \
  "Pre-commit: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/core/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 9: Pre-commit validation ignores non-commit commands
test_hook \
  "Pre-commit: Ignores non-commit git commands" \
  "plugins/core/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 9: Pre-commit validation ignores non-git commands
test_hook \
  "Pre-commit: Ignores non-git commands" \
  "plugins/core/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"ls -la\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

# Test 10: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit: Uses git -C directory instead of CWD" \
  "plugins/core/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/core/precommit-test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("Core plugin"))'

# Test 11: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit: Falls back to CWD when -C path is invalid" \
  "plugins/core/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

print_summary
