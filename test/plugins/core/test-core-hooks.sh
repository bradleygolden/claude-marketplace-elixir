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

# Test 3.1: Auto-format hook processes .heex files
test_hook \
  "Auto-format hook: Processes .heex template files" \
  "plugins/core/scripts/auto-format.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/autoformat-test/lib/test_template.heex\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/autoformat-test\"}" \
  0 \
  ""

# Test 3.2: Auto-format hook processes .leex files
test_hook \
  "Auto-format hook: Processes .leex template files" \
  "plugins/core/scripts/auto-format.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/autoformat-test/lib/test_template.leex\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/autoformat-test\"}" \
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

# Test 5.1: Compile check processes .heex files
test_hook \
  "Compile check: Processes .heex template files" \
  "plugins/core/scripts/compile-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/autoformat-test/lib/test_template.heex\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/autoformat-test\"}" \
  0 \
  ""

# Test 5.2: Compile check processes .leex files
test_hook \
  "Compile check: Processes .leex template files" \
  "plugins/core/scripts/compile-check.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/autoformat-test/lib/test_template.leex\"},\"cwd\":\"$REPO_ROOT/test/plugins/core/autoformat-test\"}" \
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

# Test 16: Read hook detects dependencies from direct module usage
test_hook_json \
  "Read hook: Detects dependencies from direct module usage (Jason.decode)" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/test_file.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("jason")) and (.hookSpecificOutput.additionalContext | contains("ecto"))'

# Test 17: Read hook ignores non-Elixir files
test_hook_json \
  "Read hook: Ignores non-Elixir files" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/README.md\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '. == {}'

# Test 18: Read hook returns empty when file has no dependency references
test_hook_json \
  "Read hook: Returns empty when no dependency references found" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/broken_code.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '. == {}'

# Test 19: File using Jason.decode() matches jason dependency
test_hook_json \
  "Read hook: Matches jason when file uses Jason.decode()" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("jason")'

# Test 20: File using Jason does not match unrelated ecto dependency
test_hook_json \
  "Read hook: Excludes ecto when file only uses Jason" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("ecto")) | not'

# Test 21: File using Jason does not match unrelated decimal dependency
test_hook_json \
  "Read hook: Excludes decimal when file only uses Jason" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("decimal")) | not'

# Test 22: File using Jason does not match unrelated telemetry dependency
test_hook_json \
  "Read hook: Excludes telemetry when file only uses Jason" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/specific_deps_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("telemetry")) | not'

# Test 23: File importing Phoenix.LiveView matches both phoenix and phoenix_live_view
test_hook_json \
  "Read hook: Matches phoenix_live_view when file imports Phoenix.LiveView" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | contains("phoenix_live_view")'

# Test 24: File importing Phoenix.LiveView also matches base phoenix dependency
test_hook_json \
  "Read hook: Matches phoenix when file imports Phoenix.LiveView" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '.hookSpecificOutput.additionalContext | test("\\bphoenix[,.]")'

# Test 25: File importing Phoenix.LiveView does not match unrelated phoenix_html
test_hook_json \
  "Read hook: Excludes phoenix_html when file imports Phoenix.LiveView" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("phoenix_html")) | not'

# Test 26: File importing Phoenix.LiveView does not match unrelated phoenix_pubsub
test_hook_json \
  "Read hook: Excludes phoenix_pubsub when file imports Phoenix.LiveView" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("phoenix_pubsub")) | not'

# Test 27: File importing Phoenix.LiveView does not match unrelated phoenix_template
test_hook_json \
  "Read hook: Excludes phoenix_template when file imports Phoenix.LiveView" \
  "plugins/core/scripts/recommend-docs-on-read.sh" \
  "{\"tool_input\":{\"file_path\":\"$REPO_ROOT/test/plugins/core/compile-test/lib/phoenix_liveview_test.ex\"},\"hook_event_name\":\"PostToolUse\",\"tool_name\":\"Read\"}" \
  0 \
  '(.hookSpecificOutput.additionalContext | contains("phoenix_template")) | not'

print_summary
