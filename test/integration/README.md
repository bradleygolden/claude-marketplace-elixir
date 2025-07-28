# Claude Code Hooks Integration Tests

This directory contains integration tests that verify the complete flow of Claude Code → Hooks → Telemetry.

## Overview

These tests actually invoke Claude Code to perform operations and then verify that:
1. The appropriate hooks are triggered
2. Telemetry events are emitted correctly
3. The hooks execute as expected

## Requirements

- Claude Code must be installed and available in your PATH
- The project must have its dependencies installed (`mix deps.get`)
- Tests require actual file system operations and git repositories

## Running Integration Tests

By default, integration tests are excluded. To run them:

```bash
# Run only integration tests
RUN_INTEGRATION_TESTS=true mix test --only integration

# Run all tests including integration
RUN_INTEGRATION_TESTS=true mix test

# Run with telemetry debugging enabled
DEBUG_TELEMETRY=true RUN_INTEGRATION_TESTS=true mix test --only integration
```

## Test Structure

### TelemetryHelpers (`test/support/telemetry_helpers.ex`)

Provides utilities for:
- Setting up telemetry event collection
- Asserting hook execution success/failure
- Collecting and filtering telemetry events

Key functions:
- `setup_telemetry/1` - Attaches telemetry handlers for the test
- `assert_hook_success/2` - Asserts a hook executed successfully
- `assert_hook_exception/2` - Asserts a hook raised an exception
- `collect_telemetry_events/0` - Collects all events from the mailbox
- `wait_for_events/3` - Waits for a specific number of matching events

### ClaudeCodeHelpers (`test/support/claude_code_helpers.ex`)

Provides utilities for invoking Claude Code:
- `run_claude/3` - Runs Claude with a prompt and permissions
- `claude_edit_file/5` - Creates and edits a file
- `claude_bash/3` - Runs bash commands through Claude
- `claude_create_file/4` - Creates new files
- `claude_search/3` - Searches for patterns

### Test Organization

Tests are organized by hook type:
- **PostToolUse hooks** - Test formatter and compilation checker
- **PreToolUse hooks** - Test pre-commit checks
- **Complex scenarios** - Test multi-tool operations

Each describe block shares a project to improve performance while tests use unique file names to avoid conflicts.

## Example Test

```elixir
test "formatter runs on new file creation", %{project: project} do
  timestamp = System.unique_integer([:positive])
  file_name = "lib/test_#{timestamp}.ex"
  
  # Invoke Claude to create a file
  {:ok, _output} = claude_create_file(
    file_name,
    "Create a module with poor formatting",
    project
  )
  
  # Assert the formatter hook executed
  {measurements, metadata} = assert_hook_success("post_tool_use.elixir_formatter",
    tool_name: "Write"
  )
  
  # Verify the result
  content = File.read!(Path.join(project.root, file_name))
  assert content =~ ~r/properly formatted/
end
```

## Telemetry Events

The hooks emit standard telemetry events:
- `[:claude, :hook, :start]` - When a hook begins execution
- `[:claude, :hook, :stop]` - When a hook completes successfully
- `[:claude, :hook, :exception]` - When a hook raises an exception

Each event includes metadata such as:
- `:hook_identifier` - The hook that was executed
- `:tool_name` - The Claude tool that triggered the hook
- `:session_id` - The Claude session ID
- `:duration` - Execution time (stop/exception events)

## Troubleshooting

### Claude not found
Ensure Claude Code is installed and in your PATH:
```bash
which claude
```

### Tests timeout
Integration tests have a 2-minute timeout. If tests are timing out:
- Check that Claude Code is responding properly
- Verify no permission prompts are blocking execution
- Use more specific allowed tools to reduce processing time

### Debugging failures
Enable verbose output:
```bash
DEBUG_TELEMETRY=true RUN_INTEGRATION_TESTS=true mix test --only integration --trace
```

This will show:
- All telemetry events as they're emitted
- Claude Code output
- Detailed error messages

## Best Practices

1. **Use unique identifiers** - Always use timestamps or unique integers in file names
2. **Clean up resources** - Projects are automatically cleaned up via `on_exit`
3. **Be specific with permissions** - Only allow the tools needed for each test
4. **Test one thing** - Each test should verify a specific behavior
5. **Use shared projects** - Tests in the same describe block share a project for efficiency