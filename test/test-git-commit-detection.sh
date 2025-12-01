#!/usr/bin/env bash

# Shared test functions for git commit command detection in pre-commit hooks
# Verifies that various git commit command formats are properly detected
#
# Usage: Source this file in plugin-specific tests and call run_git_commit_detection_tests
#
# Example:
#   source "$SCRIPT_DIR/../../test-git-commit-detection.sh"
#   run_git_commit_detection_tests \
#     "plugins/core/scripts/pre-commit-check.sh" \
#     "$REPO_ROOT/test/plugins/core/precommit-test"

# Requires test-hook.sh to be sourced first

# Helper to create test JSON input
_make_git_input() {
  local command="$1"
  local cwd="$2"
  echo "{\"tool_input\":{\"command\":\"$command\"},\"cwd\":\"$cwd\"}"
}

# Run all git commit detection tests for a given hook script
# Args:
#   $1 - Path to hook script (relative to REPO_ROOT)
#   $2 - Path to test project that triggers validation failures
#   $3 - Optional: jq assertion for success (defaults to checking permissionDecision == "deny")
run_git_commit_detection_tests() {
  local hook_script="$1"
  local test_project="$2"
  local success_assertion="${3:-.hookSpecificOutput.permissionDecision == \"deny\"}"

  echo ""
  echo "--- Tests that SHOULD match git commit ---"
  echo ""

  # Test 1: Basic git commit -m
  test_hook_json \
    "Detects: git commit -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git commit -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 2: git commit with -am flag
  test_hook_json \
    "Detects: git commit -am 'message'" \
    "$hook_script" \
    "$(_make_git_input "git commit -am 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 3: git commit --amend
  test_hook_json \
    "Detects: git commit --amend" \
    "$hook_script" \
    "$(_make_git_input "git commit --amend" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 4: git commit --amend --no-edit
  test_hook_json \
    "Detects: git commit --amend --no-edit" \
    "$hook_script" \
    "$(_make_git_input "git commit --amend --no-edit" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 5: git commit with -C flag (change directory before git)
  test_hook_json \
    "Detects: git -C /path commit -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git -C /some/path commit -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 6: git commit with --git-dir flag
  test_hook_json \
    "Detects: git --git-dir=/path commit -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git --git-dir=/some/path commit -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 7: git commit with --work-tree flag
  test_hook_json \
    "Detects: git --work-tree=/path commit -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git --work-tree=/some/path commit -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 8: Chained commands with git commit at end
  test_hook_json \
    "Detects: cd /path && git commit -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "cd /some/path && git commit -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 9: git add && git commit chain
  test_hook_json \
    "Detects: git add . && git commit -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git add . && git commit -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 10: Multiple flags before commit
  test_hook_json \
    "Detects: git -c user.name='Test' commit -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git -c user.name='Test' commit -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 11: git commit with --signoff
  test_hook_json \
    "Detects: git commit --signoff -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git commit --signoff -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  # Test 12: git commit with --gpg-sign
  test_hook_json \
    "Detects: git commit -S -m 'message'" \
    "$hook_script" \
    "$(_make_git_input "git commit -S -m 'test'" "$test_project")" \
    0 \
    "$success_assertion"

  echo ""
  echo "--- Tests that should NOT match git commit ---"
  echo ""

  # Test 13: git status should not trigger commit validation
  test_hook \
    "Ignores: git status" \
    "$hook_script" \
    "$(_make_git_input "git status" "$test_project")" \
    0 \
    ""

  # Test 14: git push should not trigger commit validation
  test_hook \
    "Ignores: git push" \
    "$hook_script" \
    "$(_make_git_input "git push origin main" "$test_project")" \
    0 \
    ""

  # Test 15: git pull should not trigger commit validation
  test_hook \
    "Ignores: git pull" \
    "$hook_script" \
    "$(_make_git_input "git pull" "$test_project")" \
    0 \
    ""

  # Test 16: git log should not trigger commit validation
  test_hook \
    "Ignores: git log" \
    "$hook_script" \
    "$(_make_git_input "git log --oneline" "$test_project")" \
    0 \
    ""

  # Test 17: git diff should not trigger commit validation
  test_hook \
    "Ignores: git diff" \
    "$hook_script" \
    "$(_make_git_input "git diff HEAD" "$test_project")" \
    0 \
    ""

  # Test 18: Non-git command should not trigger validation
  test_hook \
    "Ignores: ls -la" \
    "$hook_script" \
    "$(_make_git_input "ls -la" "$test_project")" \
    0 \
    ""

  # Test 19: Command containing "commit" but not git commit
  test_hook \
    "Ignores: echo 'commit message'" \
    "$hook_script" \
    "$(_make_git_input "echo 'commit message'" "$test_project")" \
    0 \
    ""

  # Test 20: git-commit (hyphenated, not a real git subcommand)
  test_hook \
    "Ignores: git-commit (not a git subcommand)" \
    "$hook_script" \
    "$(_make_git_input "git-commit -m 'test'" "$test_project")" \
    0 \
    ""
}
