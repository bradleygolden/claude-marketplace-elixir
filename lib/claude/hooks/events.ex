defmodule Claude.Hooks.Events do
  @moduledoc """
  Hook event structures for Claude Code.

  This module serves as the main entry point for all hook event types.
  Each event type has its own module with Input and Output structures
  where applicable.

  ## Event Types

  - `PreToolUse` - Before tool execution
  - `PostToolUse` - After tool execution  
  - `Notification` - Claude notifications
  - `UserPromptSubmit` - User prompt submission
  - `Stop` - Main agent stopping
  - `SubagentStop` - Sub-agent stopping
  - `PreCompact` - Before compaction

  ## Common Functions

  Use `Claude.Hooks.Events.Common.parse_hook_input/1` to parse incoming
  JSON into the appropriate event struct.

  Use `Claude.Hooks.Events.Common.SimpleOutput` for basic exit code
  based responses.

  ## Example

      alias Claude.Hooks.Events
      alias Claude.Hooks.Events.Common
      
      # Parse incoming hook
      case Common.parse_hook_input(json) do
        {:ok, %Events.PreToolUse.Input{tool_name: "Bash"}} ->
          # Handle bash command
          
        {:ok, event} ->
          # Handle other events
      end
  """
end
