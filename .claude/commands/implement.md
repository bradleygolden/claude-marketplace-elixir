---
description: Execute implementation plans with verification and testing
argument-hint: [plan-name]
allowed-tools: Read, Write, Edit, Grep, Glob, Task, Bash, TodoWrite, NotebookEdit, Skill
---

# Implement

You are tasked with implementing plugin marketplace features according to a detailed plan document.

## Steps to Execute:

When this command is invoked, the user provides a plan name as an argument (e.g., `/implement monitoring-plugin`). Begin implementation immediately.

1. **Load the implementation plan:**
   - If plan name provided: Read `docs/plans/plan-*-[plan-name].md`
   - If no plan name: List available plans in docs/plans/ and ask user to choose
   - Parse the plan document frontmatter and sections
   - Extract implementation steps, file changes, and validation checklist

2. **Create implementation tracking:**
   - Use TodoWrite to create todos from plan's implementation steps
   - Each step should be a separate todo item
   - Include file validation and testing as final todos
   - Structure:
     ```
     1. [in_progress] Read and parse implementation plan
     2. [pending] Create plugin metadata files
     3. [pending] Implement hook definitions
     4. [pending] Write hook scripts
     5. [pending] Create documentation
     6. [pending] Build test suite
     7. [pending] Run JSON validation
     8. [pending] Execute hook tests
     9. [pending] Update plan status
     10. [pending] Write implementation report
     11. [pending] Present implementation summary
     ```

3. **Execute implementation steps sequentially:**
   - For each step in the plan:
     - Mark todo as in_progress
     - Create or modify files as specified
     - Follow existing patterns in the codebase
     - Use proper formatting and conventions
     - Add comprehensive comments in scripts
     - Mark todo as completed when done

4. **File creation guidelines:**

   **For plugin.json files:**
   - Use proper JSON structure
   - Include all required fields: name, version, description, author, hooks
   - Follow semantic versioning (1.0.0)
   - Point hooks to correct hooks.json path

   **For hooks.json files:**
   - Define hook events (PostToolUse/PreToolUse)
   - Set tool matchers correctly
   - Reference script paths relative to plugin root
   - Use proper blocking behavior

   **For shell scripts:**
   - Include shebang: `#!/bin/bash`
   - Set error handling: `set -euo pipefail`
   - Add comprehensive comments
   - Use jq for JSON operations
   - Implement proper exit codes
   - Generate correct JSON output patterns
   - Make scripts executable: `chmod +x`

   **For test scripts:**
   - Source test utilities: `source ../../test-hook.sh`
   - Test all scenarios: file type filtering, command matching, blocking behavior
   - Verify exit codes and JSON output
   - Use descriptive test names

   **For README.md files:**
   - Include sections: Overview, Features, Installation, Usage, Hooks, Examples
   - Document all hooks and their behavior
   - Provide installation instructions
   - Include usage examples

5. **Validation during implementation:**
   - After creating JSON files, validate with jq:
     ```bash
     jq . file.json > /dev/null && echo "Valid JSON"
     ```
   - After creating shell scripts, check syntax:
     ```bash
     bash -n script.sh
     ```
   - After modifications, verify file structure:
     ```bash
     ls -la plugins/[name]/
     ```

6. **Run comprehensive testing:**
   - Execute hook test suite:
     ```bash
     ./test/plugins/[name]/test-[name]-hooks.sh
     ```
   - Verify all tests pass
   - If tests fail, debug and fix issues
   - Re-run tests until all pass

7. **Update marketplace registration (for new plugins):**
   - Edit `.claude-plugin/marketplace.json`
   - Add plugin to plugins array with metadata
   - Validate JSON structure with jq
   - Follow existing plugin patterns

8. **Update documentation:**
   - Update marketplace README.md to list new plugin
   - Update CLAUDE.md if architecture changes
   - Ensure all documentation is consistent

9. **Final validation checklist:**
   - Run through plan's validation checklist
   - Verify all items are complete
   - Check JSON validity: `jq . .claude-plugin/marketplace.json`
   - Check plugin structure exists
   - Verify hooks.json is valid
   - Confirm scripts are executable
   - Validate README.md completeness
   - Ensure tests pass

10. **Update plan status:**
    - Read the plan document
    - Update frontmatter status from "draft" to "implemented"
    - Add implementation metadata:
      ```yaml
      implemented_date: [Current date]
      implementer: [Git user name]
      implementation_commit: [Current commit hash]
      implementation_notes: "[Brief summary of implementation]"
      ```
    - Save updated plan

11. **Write implementation report:**
    - Create `.thoughts/` directory if it doesn't exist
    - Write comprehensive implementation report to `.thoughts/YYYY-MM-DD-implementation-[feature-name].md`
    - Include:
      - Implementation summary
      - Plan followed (name and path)
      - Files created/modified with paths
      - Test results (pass/fail, command output)
      - Deviations from plan (if any)
      - Implementation timeline
      - Next steps

12. **Present implementation summary:**
    - Show concise summary of what was implemented
    - List all files created/modified with paths
    - Report test results
    - Highlight any deviations from plan
    - Reference detailed report: `.thoughts/YYYY-MM-DD-implementation-[feature-name].md`
    - Suggest next steps (commit, test in Claude Code, etc.)

## Implementation Patterns:

### New Plugin Implementation
1. Create directory: `plugins/[name]/`
2. Create `.claude-plugin/plugin.json`
3. Create `hooks/hooks.json`
4. Create `scripts/` directory and hook scripts
5. Make scripts executable
6. Create `README.md`
7. Create test directory: `test/plugins/[name]/`
8. Create test script: `test-[name]-hooks.sh`
9. Add plugin to marketplace.json
10. Run tests
11. Update documentation

### Hook Modification Implementation
1. Backup existing hooks.json
2. Update hook definitions
3. Modify or create scripts
4. Update tests to cover new behavior
5. Run tests
6. Update plugin README.md
7. Verify backward compatibility

### Testing Enhancement Implementation
1. Identify test gaps
2. Add new test scenarios
3. Update test utilities if needed
4. Run all tests
5. Document new test patterns

## Error Handling:

- If a file creation fails, stop and report the error
- If JSON validation fails, fix and retry
- If tests fail, debug and fix before proceeding
- If plan is ambiguous, ask for clarification
- Keep user informed of progress throughout

## Best Practices:

- Follow existing code patterns in the marketplace
- Write clear, commented shell scripts
- Use proper JSON formatting with jq
- Make scripts defensive with error handling
- Test thoroughly at each step
- Keep documentation synchronized with implementation
- Use semantic commit messages if creating commits
- Mark todos as completed immediately after finishing each step

## Plugin-Specific Implementation Notes:

### Hook Script Structure
```bash
#!/bin/bash
set -euo pipefail

# Extract tool input using jq
TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_input')
FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
COMMAND=$(echo "$TOOL_INPUT" | jq -r '.command // empty')

# Filter by file type or command
if ! echo "$FILE_PATH" | grep -qE '\.(ex|exs)$'; then
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Perform validation/analysis
OUTPUT=$(some_command)

# Generate JSON output
if [[ -z "$OUTPUT" ]]; then
  jq -n '{"suppressOutput": true}'
  exit 0
else
  jq -n \
    --arg context "$OUTPUT" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": $context
      }
    }'
  exit 0
fi
```

### Test Script Structure
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../test-hook.sh"

test_hook_on_matching_file() {
  # Test logic
  assert_exit_code 0 "$EXIT_CODE"
  assert_json_valid "$OUTPUT"
}

run_test "Hook triggers on matching file" test_hook_on_matching_file
```

## Important Notes:

- Implementation should strictly follow the plan
- Any deviations should be documented and justified
- Testing is mandatory - don't skip tests
- JSON validation is critical - always verify
- Keep the user informed of progress
- Update plan status when complete
- Use TodoWrite to track implementation progress
- Mark todos completed immediately after each step

## Example Usage:

**User**: `/implement monitoring-plugin`

**Process**:
1. Read `docs/plans/plan-2025-10-26-monitoring-plugin.md`
2. Create TodoWrite with all implementation steps
3. Create `plugins/monitoring/.claude-plugin/plugin.json`
4. Create `plugins/monitoring/hooks/hooks.json`
5. Create `plugins/monitoring/scripts/health-check.sh`
6. Make scripts executable
7. Create `plugins/monitoring/README.md`
8. Create `test/plugins/monitoring/test-monitoring-hooks.sh`
9. Run tests: `./test/plugins/monitoring/test-monitoring-hooks.sh`
10. Add plugin to `.claude-plugin/marketplace.json`
11. Update `README.md`
12. Update plan status to "implemented"
13. Present implementation summary

**User**: `/implement` (no plan name)

**Process**:
1. List available plans in docs/plans/
2. Show user the options
3. Ask which plan to implement
4. Proceed with selected plan
