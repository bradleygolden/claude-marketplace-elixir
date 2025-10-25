#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

echo "Testing mix_audit Plugin Hooks"
echo "================================"
echo ""

test_hook \
  "Pre-commit check: Ignores non-commit git commands (git status)" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git status\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Ignores non-git commands (npm install)" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"npm install\"},\"cwd\":\"$REPO_ROOT\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Ignores non-Elixir projects" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test\"}" \
  0 \
  ""

test_hook \
  "Pre-commit check: Skips when mix_audit not in dependencies" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/mix_audit/no-audit-test\"}" \
  0 \
  ""

test_hook_json \
  "Pre-commit check: Attempts to run mix deps.audit when mix_audit present" \
  "plugins/mix_audit/scripts/pre-commit-check.sh" \
  "{\"tool_input\":{\"command\":\"git commit -m 'test'\"},\"cwd\":\"$REPO_ROOT/test/plugins/mix_audit/precommit-test\"}" \
  0 \
  '.suppressOutput == true or .hookSpecificOutput.permissionDecision == "deny"'

print_summary
