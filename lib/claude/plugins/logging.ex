defmodule Claude.Plugins.Logging do
  @moduledoc """
  Logging plugin for Claude Code that automatically configures JSONL event logging.

  This plugin provides comprehensive event logging for Claude Code sessions,
  capturing all hook events to JSONL files for analysis and monitoring.

  ## Features

  - **Automatic Configuration**: Enables JSONL logging with sensible defaults
  - **All Events Captured**: Logs every hook event type (pre_tool_use, post_tool_use, stop, etc.)
  - **Daily Rotation**: Creates new log files daily for easy management
  - **Standard Format**: JSONL output works with common log analysis tools
  - **Non-blocking**: Async logging doesn't slow down Claude Code operations

  ## Default Configuration

  When enabled, this plugin automatically configures:

      reporters: [
        {:jsonl,
          path: ".claude/logs",
          filename_pattern: "events-{date}.jsonl",
          enabled: true,
          create_dirs: true
        }
      ]

  ## Customization

  You can override the default settings by passing options to the plugin:

      plugins: [
        {Claude.Plugins.Logging, 
          path: "/var/log/claude",
          filename_pattern: "claude-events-{datetime}.jsonl",
          enabled: true
        }
      ]

  ## Plugin Options

  - `:path` - Directory for log files (default: ".claude/logs")
  - `:filename_pattern` - Pattern for log file names (default: "events-{date}.jsonl")
  - `:enabled` - Whether to enable logging (default: `true`)
  - `:create_dirs` - Whether to create log directories automatically (default: `true`)

  ## Log Analysis Examples

  Once enabled, you can analyze your Claude Code sessions:

      # View recent tool usage
      tail -f .claude/logs/events-$(date +%Y-%m-%d).jsonl | jq '.tool'

      # Count events by type today
      cat .claude/logs/events-$(date +%Y-%m-%d).jsonl | jq -r '.event' | sort | uniq -c

      # Find all file edits
      cat .claude/logs/events-*.jsonl | jq 'select(.tool == "Edit" or .tool == "Write")'

      # Track a specific session
      cat .claude/logs/events-*.jsonl | jq 'select(.session_id == "your-session-id")'

  ## Log Management

  The plugin creates log files but does not automatically clean them up.
  Consider implementing log rotation using:

  - `logrotate` on Linux/macOS
  - Custom cleanup scripts
  - External log management tools

  ## Security Notes

  - Log files may contain sensitive project information
  - Ensure appropriate file permissions on log directories  
  - Consider log retention policies for sensitive projects
  - Review logs before sharing as they contain detailed activity data
  """

  @behaviour Claude.Plugin

  @impl true
  def config(opts) do
    enabled? = Keyword.get(opts, :enabled, true)

    if enabled? do
      %{
        # Declare all hook events with empty arrays to ensure registration
        # This ensures ALL events flow through to reporters even if no actual hooks are configured
        hooks: %{
          pre_tool_use: [],
          post_tool_use: [],
          stop: [],
          subagent_stop: [],
          user_prompt_submit: [],
          notification: [],
          pre_compact: [],
          session_start: []
        },
        reporters: [
          {:jsonl, build_reporter_config(opts)}
        ]
      }
    else
      %{}
    end
  end

  defp build_reporter_config(opts) do
    [
      path: Keyword.get(opts, :path, ".claude/logs"),
      filename_pattern: Keyword.get(opts, :filename_pattern, "events-{date}.jsonl"),
      enabled: Keyword.get(opts, :enabled, true),
      create_dirs: Keyword.get(opts, :create_dirs, true)
    ]
  end
end
