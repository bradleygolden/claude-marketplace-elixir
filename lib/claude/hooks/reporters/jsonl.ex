defmodule Claude.Hooks.Reporters.Jsonl do
  @moduledoc """
  JSONL (JSON Lines) reporter for Claude hooks events.

  Writes each event as a single line of JSON to a log file, making it easy to
  process events with tools like `jq`, `grep`, or any log analysis system.

  ## Configuration

  Configure in your `.claude.exs`:

      reporters: [
        {:jsonl,
          path: ".claude/logs",
          filename_pattern: "events-{date}.jsonl",
          enabled: true
        }
      ]

  ## Options

  - `:path` - Directory for log files (default: ".claude/logs")
  - `:filename_pattern` - Pattern for log file names (default: "events-{date}.jsonl")
    - `{date}` is replaced with current date in YYYY-MM-DD format
    - `{datetime}` is replaced with current datetime in YYYY-MM-DD_HH-MM-SS format
  - `:enabled` - Whether to enable logging (default: `true`)
  - `:create_dirs` - Whether to create log directories automatically (default: `true`)

  ## Output Format

  Each line contains a JSON object with:
  - `timestamp` - ISO 8601 timestamp when the event occurred
  - `session_id` - Claude Code session identifier
  - `event` - Hook event name (e.g., "post_tool_use", "stop")
  - `tool` - Tool name for tool-related events
  - `data` - Complete event data from Claude Code

  ## Example Output

      {"timestamp":"2024-01-20T15:30:45.123Z","session_id":"abc123","event":"post_tool_use","tool":"Write","data":{"tool_input":{"file_path":"/src/app.ex"}}}
      {"timestamp":"2024-01-20T15:30:46.456Z","session_id":"abc123","event":"stop","tool":null,"data":{"stop_hook_active":false}}

  ## Querying Logs

  Use `jq` to analyze your logs:

      # View all write operations
      cat .claude/logs/events-2024-01-20.jsonl | jq 'select(.tool == "Write")'

      # Count events by type
      cat .claude/logs/events-2024-01-20.jsonl | jq -r '.event' | sort | uniq -c

      # Get all events from a specific session
      cat .claude/logs/events-*.jsonl | jq 'select(.session_id == "abc123")'

  ## Log Rotation

  By default, logs rotate daily based on the filename pattern. Old logs are
  retained indefinitely. You can implement your own cleanup strategy or use
  external tools like `logrotate`.

  ## Security Considerations

  - Log files may contain sensitive information from Claude Code events
  - Ensure appropriate file permissions on log directories
  - Consider log retention policies for sensitive projects
  - Be careful when sharing logs as they may contain project-specific data
  """

  @behaviour Claude.Hooks.Reporter
  require Logger

  @impl true
  def report(event_data, opts) do
    case build_log_entry(event_data) do
      {:ok, log_entry} ->
        write_to_file(log_entry, opts)

      {:error, reason} ->
        Logger.warning("Failed to build log entry: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_log_entry(event_data) when is_map(event_data) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    log_entry = %{
      timestamp: timestamp,
      session_id: Map.get(event_data, "session_id"),
      event: Map.get(event_data, "hook_event_name"),
      tool: Map.get(event_data, "tool_name"),
      data: event_data
    }

    case Jason.encode(log_entry) do
      {:ok, json} -> {:ok, json <> "\n"}
      {:error, reason} -> {:error, {:json_encode_failed, reason}}
    end
  end

  defp build_log_entry(_invalid_data) do
    {:error, :invalid_event_data}
  end

  defp write_to_file(log_entry, opts) do
    log_path = get_log_path(opts)

    case ensure_log_directory(log_path, opts) do
      :ok ->
        File.write(log_path, log_entry, [:append])

      {:error, reason} ->
        Logger.warning("Failed to create log directory for #{log_path}: #{inspect(reason)}")
        {:error, {:directory_creation_failed, reason}}
    end
  end

  defp get_log_path(opts) do
    base_path = Keyword.get(opts, :path, ".claude/logs")
    filename_pattern = Keyword.get(opts, :filename_pattern, "events-{date}.jsonl")

    filename = expand_filename_pattern(filename_pattern)
    Path.join(base_path, filename)
  end

  defp expand_filename_pattern(pattern) do
    now = DateTime.utc_now()
    date = Date.to_iso8601(now)

    datetime =
      DateTime.to_iso8601(now)
      |> String.replace(~r/[:\-T]/, "_")
      |> String.replace(~r/\.\d+Z$/, "")

    pattern
    |> String.replace("{date}", date)
    |> String.replace("{datetime}", datetime)
  end

  defp ensure_log_directory(log_path, opts) do
    create_dirs? = Keyword.get(opts, :create_dirs, true)

    if create_dirs? do
      log_path
      |> Path.dirname()
      |> File.mkdir_p()
    else
      :ok
    end
  end
end
