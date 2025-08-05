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

  ## Example

      alias Claude.Hooks.Events
      
      # Parse specific event type
      case Events.PreToolUse.Input.from_json(json) do
        {:ok, %Events.PreToolUse.Input{tool_name: "Bash"}} ->
          # Handle bash command
          
        {:error, reason} ->
          # Handle parse error
      end
  """
end
