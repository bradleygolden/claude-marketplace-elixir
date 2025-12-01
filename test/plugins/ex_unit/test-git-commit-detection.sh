#!/usr/bin/env bash

# Git commit detection tests for ExUnit plugin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"
source "$SCRIPT_DIR/../../test-git-commit-detection.sh"

echo "Testing ExUnit Plugin Git Commit Detection"
echo "==========================================="

# Use a test project that will trigger the hook (has failing tests)
TEST_PROJECT="$REPO_ROOT/test/plugins/ex_unit/precommit-test"

run_git_commit_detection_tests \
  "plugins/ex_unit/scripts/pre-commit-test.sh" \
  "$TEST_PROJECT"

print_summary
