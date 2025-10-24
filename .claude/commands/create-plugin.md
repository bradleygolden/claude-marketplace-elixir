---
description: Scaffold a new plugin structure with optional guided mode
argument-hint: <plugin-name> [--guided]
allowed-tools: Bash, Write, Edit, Read, Glob, Grep, TodoWrite, Task, AskUserQuestion
---

# Create Plugin Command

This command scaffolds a new plugin structure for the Elixir marketplace, with an optional guided mode that shows examples from existing plugins to help inform your implementation.

## Usage

```
/create-plugin <plugin-name>
/create-plugin <plugin-name> --guided
```

## Instructions

### Step 1: Validate Plugin Name

Check if the plugin already exists:
```bash
ls plugins/<plugin-name> 2>/dev/null
```

If it exists, inform the user and stop. Otherwise, proceed.

### Step 2: Determine Mode

Check if `--guided` flag was provided in the command.

**If NO --guided flag**: Skip to Step 8 (Quick Scaffold Mode)

**If --guided flag present**: Continue with guided mode below

---

## Guided Mode (Steps 3-7)

### Step 3: Welcome and Gather Information

Present guided mode introduction:

```
Guided Plugin Creation Mode

I'll help you create '<plugin-name>' by first showing you examples from
existing plugins in the marketplace. This will help you understand common
patterns and make informed implementation decisions.

Let me ask you a few questions about your plugin...
```

Use AskUserQuestion tool to gather information:

**Question 1**: "What will this plugin do?"
- **Header**: "Purpose"
- **Question**: "What is the main purpose of this plugin?"
- **Options**:
  - Label: "Code analysis/linting", Description: "Analyze code quality, style, or potential issues (like credo, dialyzer)"
  - Label: "Auto-formatting", Description: "Automatically format code when files are edited (like mix format)"
  - Label: "Testing automation", Description: "Run tests or test-related tasks automatically"
  - Label: "Build/compilation", Description: "Handle compilation, builds, or related tasks"

**Question 2**: "Will your plugin use hooks?"
- **Header**: "Hooks"
- **Question**: "Will this plugin use Claude Code hooks to automate tasks?"
- **multiSelect**: true
- **Options**:
  - Label: "PostToolUse", Description: "Run after file edits/writes (e.g., auto-format, compile check)"
  - Label: "PreToolUse", Description: "Run before commands execute (e.g., pre-commit validation)"
  - Label: "No hooks", Description: "This plugin won't use hooks"

**Question 3**: "Implementation approach?"
- **Header**: "Approach"
- **Question**: "How will your hooks execute their logic?"
- **Options**:
  - Label: "Inline commands", Description: "Execute commands directly in hooks.json (simpler, good for short commands)"
  - Label: "External scripts", Description: "Use separate bash scripts (better for complex logic, reusability)"
  - Label: "Not sure", Description: "Show me both approaches"

### Step 4: Create Research Plan

Use TodoWrite to track guided creation:

```
⏳ Gather examples from similar plugins
⏳ Show relevant implementation patterns
⏳ Create plugin scaffold
⏳ Provide next steps guidance
```

### Step 5: Find Similar Plugins and Patterns

Based on user's answers, use the Task tool with `subagent_type="finder"` to show examples:

```
Use the Task tool with subagent_type="finder" to find examples relevant to creating a plugin
with these characteristics:

Purpose: [answer from Q1]
Hook types: [answer from Q2]
Implementation: [answer from Q3]

Please:
1. Find plugins in the marketplace with similar purpose or hook types
2. Show their implementation approaches:
   - If they use PostToolUse: Show examples with file:line references
   - If they use PreToolUse: Show examples with file:line references
   - If inline commands: Show inline hook examples
   - If external scripts: Show script organization and helper functions
3. Extract key patterns that would be relevant:
   - Stdin handling patterns
   - Project root detection (if applicable)
   - File filtering (if applicable)
   - Output formatting
4. Show test suite patterns from similar plugins

Focus on showing concrete code examples that can serve as inspiration.

Return organized findings with file:line references for all examples.
```

### Step 6: Present Findings to User

Update TodoWrite: ✅ Gather examples from similar plugins

Wait for finder to return, then present findings:

```markdown
## Marketplace Examples for '<plugin-name>'

Based on your goals, here are relevant plugins and patterns:

### Similar Plugins

**[Plugin 1]**: [Brief description]
- Purpose: [What it does]
- Location: .claude-plugin/plugins/[name]/
- Hook type: [PostToolUse/PreToolUse]
- Implementation: [Inline/External scripts]

**[Plugin 2]**: [Brief description]
- Purpose: [What it does]
- Location: .claude-plugin/plugins/[name]/
- Hook type: [PostToolUse/PreToolUse]
- Implementation: [Inline/External scripts]

---

### Relevant Patterns

#### [If they want PostToolUse]

**Pattern: PostToolUse Hook**

Used by: [list plugins]

Example (inline approach):
```json
// From .claude-plugin/plugins/core/hooks/hooks.json:7-10
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "jq -r '.tool_input.file_path' | while read FILE_PATH; do ..."
  }]
}
```

Example (external script approach):
```json
// From .claude-plugin/plugins/credo/hooks/hooks.json:7-12
{
  "matcher": "Edit|Write|MultiEdit",
  "hooks": [{
    "type": "command",
    "command": "${CLAUDE_PLUGIN_ROOT}/scripts/post-edit-check.sh",
    "timeout": 30
  }]
}
```

#### [If they want PreToolUse]

**Pattern: PreToolUse Hook**

[Similar structure showing PreToolUse examples]

#### Common Patterns

**Stdin Handling**:
- Pipeline pattern: `jq -r '.field' | while read VAR; do`
- Capture pattern: `INPUT=$(cat); VAR=$(echo "$INPUT" | jq -r '.field')`

**Project Root Detection**:
```bash
# From .claude-plugin/plugins/credo/scripts/post-edit-check.sh:16-26
find_mix_project_root() {
  local dir=$(dirname "$1")
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/mix.exs" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}
```

**File Filtering**:
```bash
# Check for Elixir files
if [[ "$FILE_PATH" =~ \.(ex|exs)$ ]]; then
  # Process file
fi
```

### Test Suite Patterns

[Show examples of how similar plugins structure their tests]

---

## Recommendations

Based on marketplace patterns, consider:
- [Specific recommendation based on similar plugins]
- [Pattern that would work well for their use case]
- [Reference to specific example]

```

Update TodoWrite: ✅ Show relevant implementation patterns

### Step 7: Confirm and Proceed

Ask the user:

```
I've shown you examples from the marketplace. Would you like to:
1. Proceed with creating the scaffold
2. See more details about a specific pattern
3. Research something else first

Reply with your choice, and I'll proceed accordingly.
```

If they choose 1 (proceed), continue to Step 8.
If they choose 2, use Task tool with `subagent_type="analyzer"` for deep analysis of specific pattern.
If they choose 3, ask what they want to research.

---

## Quick Scaffold Mode (Step 8)

*This runs either after guided mode completes, or immediately if no --guided flag*

### Step 8: Create Plugin Directory Structure

Use TodoWrite to update: ⏳ Create plugin scaffold → in progress

Create the following directories:

```bash
mkdir -p plugins/<plugin-name>/.claude-plugin
mkdir -p test/plugins/<plugin-name>
```

### Step 9: Create plugin.json

Create `plugins/<plugin-name>/.claude-plugin/plugin.json`:

```json
{
  "name": "<plugin-name>",
  "version": "1.0.0",
  "description": "TODO: Add plugin description",
  "author": {
    "name": "Bradley Golden",
    "url": "https://github.com/bradleygolden"
  },
  "repository": "https://github.com/bradleygolden/claude-marketplace-elixir",
  "license": "MIT",
  "keywords": []
}
```

### Step 10: Create Plugin README

Create `plugins/<plugin-name>/README.md`:

```markdown
# <plugin-name>

TODO: Add plugin description

## Installation

\`\`\`bash
/plugin marketplace add github:bradleygolden/claude-marketplace-elixir
/plugin install <plugin-name>@elixir
\`\`\`

## Features

TODO: Document plugin features

## Usage

TODO: Document how to use this plugin

## Configuration

TODO: Document any configuration options
```

### Step 11: Create Test README

Create `test/plugins/<plugin-name>/README.md`:

```markdown
# <plugin-name> Test Suite

This test suite validates the <plugin-name>@elixir plugin.

**Prerequisite**: The <plugin-name>@elixir plugin must be installed before running this test.

## Test 1: TODO

### Setup
TODO: Document test setup

### Test Steps
TODO: Document test steps

### Expected Behavior
TODO: Document expected behavior

## Summary Format

After completing all tests, provide a summary:

\`\`\`
✅/❌ Test 1 - Description
✅/❌ Test 2 - Description

Overall result: PASS/FAIL
\`\`\`
```

### Step 12: Update marketplace.json

Add the plugin to `.claude-plugin/marketplace.json` in the `plugins` array:

1. Read the current marketplace.json
2. Parse it with jq
3. Add new entry to the plugins array:

```json
{
  "name": "<plugin-name>",
  "source": "./plugins/<plugin-name>",
  "description": "TODO: Add plugin description",
  "keywords": [],
  "repository": "https://github.com/bradleygolden/claude-marketplace-elixir",
  "license": "MIT",
  "homepage": "https://github.com/bradleygolden/claude-marketplace-elixir"
}
```

### Step 13: Validate

Validate all JSON files:

```bash
jq . plugins/<plugin-name>/.claude-plugin/plugin.json
jq . .claude-plugin/marketplace.json
```

### Step 14: Summary and Next Steps

Update TodoWrite:
- ✅ Create plugin scaffold → completed
- ✅ Provide next steps guidance → in progress

Provide the user with a summary:

```markdown
✅ Plugin scaffold created for '<plugin-name>'

## Created Structure

```
plugins/<plugin-name>/
  ├── .claude-plugin/
  │   └── plugin.json
  └── README.md
test/plugins/<plugin-name>/
  └── README.md
```

## Updated

- `.claude-plugin/marketplace.json` (added plugin entry)

---

## Next Steps

### 1. Update Metadata

Edit `plugins/<plugin-name>/.claude-plugin/plugin.json`:
- Update `description` field
- Add relevant `keywords` (array of strings)

### 2. Document Your Plugin

Edit `plugins/<plugin-name>/README.md`:
- Explain what the plugin does
- Document features and usage
- Add configuration details

### 3. Implement Functionality

**[If guided mode was used, reference the examples shown]**

You saw examples from these plugins:
- [Plugin 1]: plugins/[name]/
- [Plugin 2]: plugins/[name]/

Consider modeling your implementation after these patterns.

**[If hooks are needed]**

To add hooks:
1. Create `hooks/hooks.json` in your plugin directory
2. Reference it in plugin.json: `"hooks": "./hooks/hooks.json"`
3. Define your hooks (PostToolUse, PreToolUse, etc.)

**[If scripts are needed]**

To add external scripts:
1. Create `scripts/` directory
2. Add your .sh files (don't forget `chmod +x`)
3. Reference them in hooks.json: `"${CLAUDE_PLUGIN_ROOT}/scripts/your-script.sh"`

### 4. Create Tests

Edit `test/plugins/<plugin-name>/README.md`:
- Define test scenarios for each feature
- Include setup/teardown steps
- Document expected behavior
- Specify success criteria

**[If guided mode was used]**

Test patterns you saw:
- [Reference to test examples shown]

### 5. Validate and Test

Once implemented:
```bash
# Validate your implementation
/validate-plugin <plugin-name>

# Test it
/plugin marketplace reload
/plugin install <plugin-name>@elixir
/test-marketplace <plugin-name>
```

---

## Quick Reference

**[If guided mode was used, show a summary of key patterns]**

### Key Patterns to Reference

**Stdin handling**: [Pattern name]
- See: [file:line from examples]

**Project detection**: [Pattern name]
- See: [file:line from examples]

**Hook structure**: [Inline/External]
- See: [file:line from examples]

---

## Need Help?

- Research existing patterns: `/research "your question"`
- Get detailed examples: Use finder agent directly
- Understand implementations: Use analyzer agent directly

```

Update TodoWrite: ✅ All tasks completed

## Important Notes

- **Guided mode is optional**: Use `--guided` flag to see examples first
- **Learn from examples**: Guided mode shows working patterns from marketplace
- **Make informed decisions**: See different approaches before implementing
- **Quick scaffold available**: Skip guided mode for fast scaffolding
- **No hooks created**: Basic structure only - add hooks/scripts as needed
- **All JSON validated**: Ensures valid structure before completion

## Guided Mode Benefits

When you use `--guided`:
1. ✅ See examples from similar plugins
2. ✅ Learn common patterns (stdin, project detection, etc.)
3. ✅ Understand different approaches (inline vs external)
4. ✅ See test suite patterns
5. ✅ Make informed implementation decisions

Without `--guided`:
- ⚡ Fast scaffold creation
- Good for experienced users who know what they want
- Good for minimal plugins
