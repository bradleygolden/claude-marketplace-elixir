#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing ExUnit Plugin Hooks"
echo "================================"
echo ""

# Test 1: Pre-commit hook blocks on test failures with structured JSON
test_hook_json \
  "Pre-commit: Blocks commits when tests fail with structured JSON" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_unit/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "PreToolUse" and .hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("ExUnit")) and .systemMessage != null'

# Test 2: Pre-commit hook skips when precommit alias exists
test_hook_json \
  "Pre-commit: Skips when precommit alias exists (defers to precommit plugin)" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/precommit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 3: Pre-commit hook ignores non-commit git commands
test_hook \
  "Pre-commit: Ignores non-commit git commands" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_unit/precommit-test\"}" \
  0 \
  ""

# Test 3: Pre-commit hook ignores non-git commands
test_hook \
  "Pre-commit: Ignores non-git commands" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"ls -la\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_unit/precommit-test\"}" \
  0 \
  ""

# Test 4: Pre-commit hook skips non-Elixir projects
test_hook_json \
  "Pre-commit: Skips non-Elixir projects" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"/tmp\"}" \
  0 \
  ".suppressOutput == true"

# Test 5: Pre-commit hook skips projects without tests
TEMP_PROJECT="/tmp/ex_unit_test_no_tests_$$"
mkdir -p "$TEMP_PROJECT"
echo 'defmodule Temp.MixProject do
  use Mix.Project
  def project, do: [app: :temp, version: "0.1.0"]
end' > "$TEMP_PROJECT/mix.exs"

test_hook_json \
  "Pre-commit: Skips projects without test directory" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$TEMP_PROJECT\"}" \
  0 \
  ".suppressOutput == true"

rm -rf "$TEMP_PROJECT"

# Test 6: Pre-commit hook allows commits when tests pass
test_hook_json \
  "Pre-commit: Allows commits when tests pass" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_unit/precommit-test-pass\"}" \
  0 \
  ".suppressOutput == true"

# Test 7: Pre-commit uses -C flag directory instead of CWD
test_hook_json \
  "Pre-commit: Uses git -C directory instead of CWD" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git -C $REPO_ROOT/test/plugins/ex_unit/precommit-test commit -m 'test'\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains("ExUnit"))'

# Test 8: Pre-commit falls back to CWD when -C path is invalid
test_hook_json \
  "Pre-commit: Falls back to CWD when -C path is invalid" \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "{\"tool_input\":{\"command\":\"git -C /nonexistent/path commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/ex_unit/precommit-test\"}" \
  0 \
  '.hookSpecificOutput.permissionDecision == "deny"'

print_summary
