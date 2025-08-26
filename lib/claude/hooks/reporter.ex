defmodule Claude.Hooks.Reporter do
  @moduledoc """
  A behaviour for implementing hook event reporters and dispatching events to them.

  Reporters receive raw Claude Code hook events and handle them according to
  their implementation (webhooks, files, metrics, etc).

  ## Implementing a Reporter

  To create a custom reporter, implement the `report/2` callback:

      defmodule MyApp.CustomReporter do
        @behaviour Claude.Hooks.Reporter

        @impl true
        def report(event_data, opts) do
          :ok
        end
      end

  ## Configuration

  Reporters are configured in `.claude.exs`:

      %{
        reporters: [
          {:webhook, url: "https://example.com/events"},
          {MyApp.CustomReporter, custom_option: "value"}
        ]
      }

  ## Dispatching Events

  The dispatcher is called automatically by the hooks system:

      Claude.Hooks.Reporter.dispatch(event_data, config)
  """

  require Logger

  @type event_data :: map()
  @type opts :: keyword()
  @type report_result :: :ok | {:error, term()}

  @doc """
  Called for each hook event that needs to be reported.

  The `event_data` is the raw JSON data from Claude Code's hook system,
  containing fields like:
  - `"hook_event_name"` - The type of event
  - `"tool_name"` - For tool-related events
  - `"session_id"` - Unique session identifier
  - Event-specific fields

  The `opts` come directly from the reporter configuration in `.claude.exs`.

  This function should handle its own error recovery and logging.
  Return `:ok` for success or `{:error, reason}` for failure.

  ## Example

      @impl true
      def report(event_data, opts) do
        case send_to_service(event_data, opts) do
          {:ok, _} -> :ok
          {:error, reason} -> {:error, reason}
        end
      end
  """
  @callback report(event_data, opts) :: report_result

  @doc """
  Dispatches an event to all configured and enabled reporters.

  Reads the `:reporters` configuration from the provided config map,
  filters for enabled reporters, and executes each one synchronously.

  Errors from individual reporters are logged but don't affect other reporters.

  ## Example

      Claude.Hooks.Reporter.dispatch(event_data, config)
  """
  @spec dispatch(event_data, config :: map()) :: :ok
  def dispatch(event_data, config) do
    config
    |> Map.get(:reporters, [])
    |> Enum.filter(&enabled?/1)
    |> Enum.map(&expand_reporter/1)
    |> Enum.each(&run_reporter(&1, event_data))

    :ok
  end

  defp enabled?({_type_or_module, opts}) when is_list(opts) do
    Keyword.get(opts, :enabled, true)
  end

  defp enabled?(_), do: true

  defp expand_reporter(:webhook) do
    url = System.get_env("CLAUDE_WEBHOOK_URL")

    if url do
      {Claude.Hooks.Reporters.Webhook, [url: url]}
    else
      Logger.warning("Reporter :webhook configured but CLAUDE_WEBHOOK_URL not set")
      nil
    end
  end

  defp expand_reporter({:webhook, opts}) when is_list(opts) do
    {Claude.Hooks.Reporters.Webhook, opts}
  end

  defp expand_reporter(:jsonl) do
    {Claude.Hooks.Reporters.Jsonl, []}
  end

  defp expand_reporter({:jsonl, opts}) when is_list(opts) do
    {Claude.Hooks.Reporters.Jsonl, opts}
  end

  defp expand_reporter({module, opts}) when is_atom(module) and is_list(opts) do
    {module, opts}
  end

  defp expand_reporter({module, opts}) when is_atom(module) do
    {module, Enum.to_list(opts)}
  end

  defp expand_reporter(other) do
    Logger.warning("Invalid reporter configuration: #{inspect(other)}")
    nil
  end

  defp run_reporter(nil, _event_data), do: :ok

  defp run_reporter({module, opts}, event_data) do
    safe_report(module, opts, event_data)
    :ok
  end

  defp safe_report(module, opts, event_data) do
    Code.ensure_loaded(module)

    if function_exported?(module, :report, 2) do
      case module.report(event_data, opts) do
        :ok ->
          :ok

        {:error, reason} ->
          Logger.error("""
          Reporter #{inspect(module)} failed:
          Reason: #{inspect(reason)}
          Event: #{event_data["hook_event_name"]}
          """)

        other ->
          Logger.warning("""
          Reporter #{inspect(module)} returned unexpected value: #{inspect(other)}
          Expected :ok or {:error, reason}
          """)
      end
    else
      Logger.error("Reporter #{inspect(module)} does not implement report/2 callback")
    end
  rescue
    error ->
      Logger.error("""
      Reporter #{inspect(module)} crashed:
      #{Exception.format(:error, error, __STACKTRACE__)}
      Event: #{inspect(event_data["hook_event_name"])}
      """)
  end
end
