#!/usr/bin/env bash

# Git commit detection tests for Precommit plugin

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"
source "$SCRIPT_DIR/../../test-git-commit-detection.sh"

echo "Testing Precommit Plugin Git Commit Detection"
echo "=============================================="

# Use a test project that will trigger the hook (has precommit that fails)
TEST_PROJECT="$REPO_ROOT/test/plugins/precommit/precommit-test-fail"

run_git_commit_detection_tests \
  "plugins/precommit/scripts/pre-commit-check.sh" \
  "$TEST_PROJECT"

print_summary
