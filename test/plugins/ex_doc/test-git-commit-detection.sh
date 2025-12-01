#!/usr/bin/env bash

# Git commit detection tests for ExDoc plugin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"
source "$SCRIPT_DIR/../../test-git-commit-detection.sh"

echo "Testing ExDoc Plugin Git Commit Detection"
echo "=========================================="

# Use a test project that will trigger the hook (has doc issues)
TEST_PROJECT="$REPO_ROOT/test/plugins/ex_doc/precommit-test"

run_git_commit_detection_tests \
  "plugins/ex_doc/scripts/pre-commit-check.sh" \
  "$TEST_PROJECT"

print_summary
