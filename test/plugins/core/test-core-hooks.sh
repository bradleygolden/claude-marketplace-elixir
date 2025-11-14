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

# Test 8: Pre-commit validation ignores non-commit commands
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

# Test 10: Docs recommendation detects dependency mentions (capitalized)
test_hook_json \
  "Docs recommendation: Detects 'Ecto' in prompt" \
  "plugins/core/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Help me write an Ecto query\",\"cwd\":\"$REPO_ROOT/test/plugins/core/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '.hookSpecificOutput.hookEventName == "UserPromptSubmit" and (.hookSpecificOutput.additionalContext | contains("ecto"))'

# Test 11: Docs recommendation detects lowercase dependency names
test_hook_json \
  "Docs recommendation: Detects 'jason' (lowercase) in prompt" \
  "plugins/core/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"I need to parse json with jason\",\"cwd\":\"$REPO_ROOT/test/plugins/core/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("jason")'

# Test 12: Docs recommendation detects multiple dependencies
test_hook_json \
  "Docs recommendation: Detects multiple dependencies" \
  "plugins/core/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Use Ecto and Jason together\",\"cwd\":\"$REPO_ROOT/test/plugins/core/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("ecto")) and (.hookSpecificOutput.additionalContext | contains("jason"))'

# Test 13: Docs recommendation returns empty when no dependencies mentioned
test_hook_json \
  "Docs recommendation: Returns empty JSON when no dependencies mentioned" \
  "plugins/core/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Help me refactor this code\",\"cwd\":\"$REPO_ROOT/test/plugins/core/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '. == {}'

# Test 14: Docs recommendation works in non-Elixir projects (exits cleanly)
test_hook_json \
  "Docs recommendation: Handles non-Elixir projects gracefully" \
  "plugins/core/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"Some prompt\",\"cwd\":\"$REPO_ROOT\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '. == {}'

# Test 15: Docs recommendation recommends skills in output
test_hook_json \
  "Docs recommendation: Recommends using hex-docs-search skill" \
  "plugins/core/scripts/recommend-docs-lookup.sh" \
  "{\"prompt\":\"How do I use Ecto?\",\"cwd\":\"$REPO_ROOT/test/plugins/core/compile-test\",\"hook_event_name\":\"UserPromptSubmit\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("hex-docs-search")'

print_summary
