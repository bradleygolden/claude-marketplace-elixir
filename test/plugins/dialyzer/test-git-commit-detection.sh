#!/usr/bin/env bash

# Git commit detection tests for Dialyzer plugin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"
source "$SCRIPT_DIR/../../test-git-commit-detection.sh"

echo "Testing Dialyzer Plugin Git Commit Detection"
echo "============================================="

# Use a test project that will trigger the hook (has dialyzer errors)
TEST_PROJECT="$REPO_ROOT/test/plugins/dialyzer/precommit-test"

run_git_commit_detection_tests \
  "plugins/dialyzer/scripts/pre-commit-check.sh" \
  "$TEST_PROJECT"

print_summary
