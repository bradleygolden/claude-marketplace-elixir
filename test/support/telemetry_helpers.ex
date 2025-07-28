defmodule Claude.Test.TelemetryHelpers do
  @moduledoc """
  Helpers for collecting and asserting on telemetry events in tests.
  
  This module provides utilities for:
  - Setting up telemetry event collection in tests
  - Asserting that specific hooks were executed
  - Collecting and filtering telemetry events
  """
  
  import ExUnit.Assertions
  import ExUnit.Callbacks, only: [on_exit: 1]
  
  @doc """
  Sets up telemetry collection for the test.
  
  Attaches telemetry handlers that will send events to the test process.
  Handlers are automatically detached when the test exits.
  
  ## Examples
  
      setup :setup_telemetry
      
      # or in a test
      test "my test" do
        setup_telemetry()
        # ... test code
      end
  """
  def setup_telemetry(_context \\ %{}) do
    test_pid = self()
    handler_id = "test-handler-#{System.unique_integer()}"
    
    :telemetry.attach_many(
      handler_id,
      [
        [:claude, :hook, :start],
        [:claude, :hook, :stop],
        [:claude, :hook, :exception]
      ],
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )
    
    on_exit(fn -> :telemetry.detach(handler_id) end)
    
    {:ok, telemetry_handler_id: handler_id}
  end
  
  @doc """
  Waits for and asserts that a hook executed successfully.
  
  This function will wait for both start and stop events for the given hook,
  asserting that the hook completed without raising an exception.
  
  ## Options
  
    * `:timeout` - Maximum time to wait for events (default: 5000ms)
    * Any other options are treated as metadata assertions
  
  ## Examples
  
      # Basic usage
      assert_hook_success("post_tool_use.elixir_formatter")
      
      # With metadata assertions
      assert_hook_success("post_tool_use.elixir_formatter",
        tool_name: "Write",
        session_id: "test-123"
      )
      
      # With custom timeout
      assert_hook_success("pre_tool_use.pre_commit_check", timeout: 10_000)
  """
  def assert_hook_success(hook_identifier, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)
    metadata_assertions = Keyword.delete(opts, :timeout)
    
    # Wait for start event
    {_, _start_meta} = assert_telemetry_received(hook_identifier, :start, timeout)
    
    # Wait for stop event  
    {measurements, stop_meta} = assert_telemetry_received(hook_identifier, :stop, timeout)
    
    # Verify metadata if provided
    for {key, expected_value} <- metadata_assertions do
      actual_value = Map.get(stop_meta, key)
      assert actual_value == expected_value,
        "Expected #{key} to be #{inspect(expected_value)}, got #{inspect(actual_value)}"
    end
    
    {measurements, stop_meta}
  end
  
  @doc """
  Waits for and asserts that a hook raised an exception.
  
  ## Options
  
    * `:timeout` - Maximum time to wait for events (default: 5000ms)
    * `:expected_error` - The expected error struct or message
  
  ## Examples
  
      assert_hook_exception("post_tool_use.failing_hook")
      
      assert_hook_exception("post_tool_use.failing_hook",
        expected_error: %RuntimeError{message: "Expected failure"}
      )
  """
  def assert_hook_exception(hook_identifier, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5000)
    expected_error = Keyword.get(opts, :expected_error)
    
    # Wait for exception event
    {measurements, metadata} = assert_telemetry_received(hook_identifier, :exception, timeout)
    
    if expected_error do
      assert metadata.reason == expected_error,
        "Expected error #{inspect(expected_error)}, got #{inspect(metadata.reason)}"
    end
    
    {measurements, metadata}
  end
  
  @doc """
  Waits for a specific telemetry event and returns it.
  
  This is a lower-level function used by the assertion helpers.
  It will fail the test if the expected event is not received within the timeout.
  
  ## Examples
  
      {measurements, metadata} = assert_telemetry_received("my_hook", :start, 1000)
  """
  def assert_telemetry_received(hook_identifier, event_type, timeout) do
    receive do
      {:telemetry_event, [:claude, :hook, ^event_type], measurements, metadata} ->
        if metadata.hook_identifier == hook_identifier do
          {measurements, metadata}
        else
          # Not our hook, keep waiting
          assert_telemetry_received(hook_identifier, event_type, timeout)
        end
    after
      timeout ->
        flunk("""
        Expected telemetry event for #{hook_identifier} (#{event_type}) but none received within #{timeout}ms
        
        Did receive these events:
        #{format_received_events()}
        """)
    end
  end
  
  @doc """
  Collects all telemetry events currently in the process mailbox.
  
  This is useful for inspecting all events that have been emitted,
  particularly when debugging or when you need to assert on multiple events.
  
  ## Examples
  
      events = collect_telemetry_events()
      
      formatter_events = Enum.filter(events, fn {_, _, meta} ->
        meta.hook_identifier == "post_tool_use.elixir_formatter"
      end)
  """
  def collect_telemetry_events do
    collect_events([])
  end
  
  @doc """
  Waits for a specific number of telemetry events matching a filter.
  
  ## Examples
  
      # Wait for 2 formatter events
      events = wait_for_events(2, fn {_, _, meta} ->
        meta.hook_identifier == "post_tool_use.elixir_formatter"
      end)
  """
  def wait_for_events(count, filter_fn, timeout \\ 5000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_for_events(count, filter_fn, deadline, [])
  end
  
  # Private functions
  
  defp do_wait_for_events(0, _filter_fn, _deadline, collected), do: Enum.reverse(collected)
  
  defp do_wait_for_events(remaining, filter_fn, deadline, collected) do
    timeout = max(0, deadline - System.monotonic_time(:millisecond))
    
    receive do
      {:telemetry_event, event, measurements, metadata} = full_event ->
        if filter_fn.({event, measurements, metadata}) do
          do_wait_for_events(remaining - 1, filter_fn, deadline, [full_event | collected])
        else
          do_wait_for_events(remaining, filter_fn, deadline, collected)
        end
    after
      timeout ->
        flunk("""
        Timeout waiting for #{remaining} more events matching filter.
        Collected #{length(collected)} matching events so far.
        """)
    end
  end
  
  defp collect_events(events) do
    receive do
      {:telemetry_event, event, measurements, metadata} ->
        collect_events([{event, measurements, metadata} | events])
    after
      0 -> Enum.reverse(events)
    end
  end
  
  defp format_received_events do
    collect_events([])
    |> Enum.map(fn {event, _measurements, metadata} ->
      "  - #{inspect(event)} for #{metadata[:hook_identifier] || "unknown"}"
    end)
    |> Enum.join("\n")
  end
end