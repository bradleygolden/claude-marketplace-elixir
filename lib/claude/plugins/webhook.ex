defmodule Claude.Plugins.Webhook do
  @moduledoc """
  Webhook plugin for Claude Code that automatically configures webhook event delivery.

  This plugin provides comprehensive event delivery for Claude Code sessions,
  sending all hook events to configured webhook endpoints for integration with
  external systems and monitoring tools.

  ## Features

  - **Automatic Configuration**: Enables webhook delivery with sensible defaults
  - **All Events Captured**: Sends every hook event type (pre_tool_use, post_tool_use, stop, etc.)
  - **Flexible Headers**: Supports custom headers for context and authentication
  - **Reliable Delivery**: Includes retry logic and timeout handling
  - **Environment-Based**: Uses environment variables for secure URL configuration
  - **Non-blocking**: Async webhook delivery doesn't slow down Claude Code operations

  ## Default Configuration

  When enabled, this plugin automatically configures:

      reporters: [
        {:webhook,
          url: System.get_env("CLAUDE_WEBHOOK_URL"),
          headers: %{
            "Content-Type" => "application/json"
          },
          timeout: 5000,
          retry_count: 3
        }
      ]

  ## Usage

  ### Basic Usage

  Simply add the plugin to your `.claude.exs`:

      plugins: [Claude.Plugins.Base, Claude.Plugins.Webhook]

  Then set your webhook URL:

      export CLAUDE_WEBHOOK_URL="https://your-webhook-endpoint.com/claude/hooks"

  ### Advanced Configuration

  You can customize the webhook configuration by passing options:

      # Define git helper functions in .claude.exs
      git_cmd = fn args ->
        case System.cmd("git", args, cd: System.get_env("CLAUDE_PROJECT_DIR", ".")) do
          {output, 0} -> String.trim(output)
          _ -> ""
        end
      end

      get_git_branch = fn -> git_cmd.(["branch", "--show-current"]) end
      get_git_commit = fn -> git_cmd.(["rev-parse", "HEAD"]) end

      plugins: [
        {Claude.Plugins.Webhook, 
          url: "https://custom-endpoint.com/hooks",
          timeout: 10000,
          retry_count: 5,
          headers: %{
            "Content-Type" => "application/json",
            "Authorization" => "Bearer " <> System.get_env("WEBHOOK_TOKEN"),
            "X-Git-Branch" => get_git_branch.(),
            "X-Git-Commit" => get_git_commit.(),
            "X-Custom-Header" => "custom-value"
          }
        }
      ]

  ## Plugin Options

  - `:url` - Webhook URL (default: reads from `CLAUDE_WEBHOOK_URL` env var)
  - `:timeout` - Request timeout in milliseconds (default: 5000)
  - `:retry_count` - Number of retries for failed requests (default: 3)
  - `:headers` - Custom headers map (default: only Content-Type)
  - `:enabled` - Whether to enable webhooks (default: `true`)


  ## Webhook Payload Format

  Each webhook receives a JSON payload with this structure:

      {
        "timestamp": 1234567890,
        "claude_event": {
          "session_id": "unique-session-id",
          "hook_event_name": "post_tool_use",
          "tool_name": "Write", 
          "tool_input": {...},
          "tool_response": {...}
        }
      }

  ## Security Best Practices

  - **Use HTTPS**: Always use HTTPS URLs for webhook endpoints
  - **Environment Variables**: Store sensitive URLs/tokens in environment variables
  - **Webhook Signing**: Consider implementing HMAC signature validation
  - **Network Restrictions**: Restrict webhook endpoint access to trusted networks
  - **Log Monitoring**: Monitor webhook delivery logs for failures or security issues

  ## Webhook Signing Example

  For production use, implement webhook signing:

      # In your webhook endpoint server
      signature = request.headers["X-Webhook-Signature"]
      payload = request.body
      secret = System.get_env("WEBHOOK_SECRET")
      
      expected = :crypto.mac(:hmac, :sha256, secret, payload)
        |> Base.encode16(case: :lower)
      
      unless Plug.Crypto.secure_compare("sha256=" <> expected, signature) do
        # Reject unsigned webhooks
      end

  Configure signing in your plugin:

      plugins: [
        {Claude.Plugins.Webhook,
          headers: %{
            "X-Webhook-Signature" => sign_payload_fn.(),
            "X-Timestamp" => to_string(System.system_time(:second))
          }
        }
      ]

  ## Troubleshooting

  ### Webhooks Not Being Sent

  1. Check that `CLAUDE_WEBHOOK_URL` is set: `echo $CLAUDE_WEBHOOK_URL`
  2. Verify the URL is accessible: `curl -X POST $CLAUDE_WEBHOOK_URL`
  3. Check webhook server logs for delivery failures
  4. Ensure the `req` dependency is installed: `mix deps.get`


  ## Integration Examples

  ### Slack Notifications

      # Webhook endpoint that posts to Slack
      def handle_webhook(event) do
        case event.claude_event.hook_event_name do
          "post_tool_use" when event.claude_event.tool_name == "Write" ->
            file_path = event.claude_event.tool_input.file_path
            branch = event.headers["X-Git-Branch"]
            slack_notify("Claude wrote file: \#{file_path} on branch \#{branch}")
          _ -> :ok
        end
      end

  ### Monitoring Dashboard

      # Store events in time-series database
      def handle_webhook(event) do
        Metrics.increment("claude.hooks.total", 
          tags: %{
            event: event.claude_event.hook_event_name,
            tool: event.claude_event.tool_name,
            branch: event.headers["X-Git-Branch"]
          }
        )
      end

  ### Audit Logging

      # Log all Claude Code activity for compliance
      def handle_webhook(event) do
        AuditLog.create(%{
          user: System.get_env("USER"),
          action: event.claude_event.hook_event_name,
          tool: event.claude_event.tool_name,
          branch: event.headers["X-Git-Branch"],
          timestamp: event.timestamp,
          details: event.claude_event
        })
      end
  """

  @behaviour Claude.Plugin

  @impl true
  def config(opts) do
    enabled? = Keyword.get(opts, :enabled, true)

    if enabled? do
      %{
        reporters: [
          {:webhook, build_reporter_config(opts)}
        ]
      }
    else
      %{}
    end
  end

  defp build_reporter_config(opts) do
    base_config = [
      url: Keyword.get(opts, :url, System.get_env("CLAUDE_WEBHOOK_URL")),
      timeout: Keyword.get(opts, :timeout, 5000),
      retry_count: Keyword.get(opts, :retry_count, 3)
    ]

    headers =
      if Keyword.has_key?(opts, :headers) do
        Keyword.get(opts, :headers)
      else
        build_default_headers()
      end

    base_config ++ [headers: headers]
  end

  defp build_default_headers do
    %{
      "Content-Type" => "application/json"
    }
  end
end
