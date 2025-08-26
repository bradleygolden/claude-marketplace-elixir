defmodule Claude.Hooks.ReporterTest do
  use Claude.ClaudeCodeCase, async: true
  use Mimic

  alias Claude.Hooks.Reporter

  import ExUnit.CaptureLog

  setup :verify_on_exit!

  defmodule TestReporter do
    @behaviour Claude.Hooks.Reporter

    @impl true
    def report(event_data, opts) do
      if pid = opts[:test_pid] do
        send(pid, {:reported, event_data, opts})
      end

      :ok
    end
  end

  defmodule FailingReporter do
    @behaviour Claude.Hooks.Reporter

    @impl true
    def report(_event_data, opts) do
      reason = Keyword.get(opts, :error_reason, "intentional failure")
      {:error, reason}
    end
  end

  defmodule CrashingReporter do
    @behaviour Claude.Hooks.Reporter

    @impl true
    def report(_event_data, opts) do
      message = Keyword.get(opts, :crash_message, "intentional crash")
      raise message
    end
  end

  defmodule InvalidReturnReporter do
    @behaviour Claude.Hooks.Reporter

    @impl true
    def report(_event_data, _opts) do
      "invalid return value"
    end
  end

  defmodule NonReporter do
    def some_function, do: :ok
  end

  describe "dispatch/2" do
    test "dispatches event to single configured reporter" do
      event_data = %{"hook_event_name" => "post_tool_use", "tool_name" => "Write"}

      config = %{
        reporters: [
          {TestReporter, test_pid: self(), custom: "value"}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_received {:reported, received_event, opts}
      assert received_event == event_data
      assert opts[:test_pid] == self()
      assert opts[:custom] == "value"
    end

    test "dispatches event to multiple reporters" do
      event_data = %{"hook_event_name" => "stop"}

      config = %{
        reporters: [
          {TestReporter, test_pid: self(), tag: "first"},
          {TestReporter, test_pid: self(), tag: "second"},
          {TestReporter, test_pid: self(), tag: "third"}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_received {:reported, ^event_data, opts1}
      assert opts1[:tag] == "first"

      assert_received {:reported, ^event_data, opts2}
      assert opts2[:tag] == "second"

      assert_received {:reported, ^event_data, opts3}
      assert opts3[:tag] == "third"
    end

    test "filters out disabled reporters" do
      event_data = %{"hook_event_name" => "pre_tool_use"}

      config = %{
        reporters: [
          {TestReporter, test_pid: self(), enabled: false, tag: "disabled"},
          {TestReporter, test_pid: self(), enabled: true, tag: "enabled"},
          {TestReporter, test_pid: self(), tag: "default"}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_received {:reported, ^event_data, opts1}
      assert opts1[:tag] == "enabled"

      assert_received {:reported, ^event_data, opts2}
      assert opts2[:tag] == "default"

      refute_received {:reported, _, _}
    end

    test "handles empty reporter list gracefully" do
      config = %{reporters: []}

      assert Reporter.dispatch(%{}, config) == :ok
    end

    test "handles missing reporters key gracefully" do
      config = %{}

      assert Reporter.dispatch(%{}, config) == :ok
    end

    test "runs reporters asynchronously by default" do
      event_data = %{"hook_event_name" => "test"}
      test_pid = self()

      config = %{
        reporters: [
          {TestReporter, test_pid: test_pid}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_receive {:reported, ^event_data, _}, 100
    end

    test "can run reporters synchronously when specified" do
      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          {TestReporter, test_pid: self()}
        ]
      }

      Reporter.dispatch(event_data, config)
      assert_received {:reported, ^event_data, _}
    end
  end

  describe "reporter expansion" do
    test "expands :webhook atom with CLAUDE_WEBHOOK_URL env var" do
      stub(System, :get_env, fn
        "CLAUDE_WEBHOOK_URL" -> "https://example.com/webhook"
        key -> System.get_env(key)
      end)

      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          :webhook,
          {TestReporter, test_pid: self()}
        ]
      }

      log =
        capture_log([level: :debug], fn ->
          Reporter.dispatch(event_data, config)
        end)

      assert log != ""

      assert_received {:reported, ^event_data, _}
    end

    test "warns when :webhook used without CLAUDE_WEBHOOK_URL env var" do
      stub(System, :get_env, fn
        "CLAUDE_WEBHOOK_URL" -> nil
        key -> System.get_env(key)
      end)

      config = %{reporters: [:webhook]}

      log =
        capture_log(fn ->
          Reporter.dispatch(%{}, config)
        end)

      assert log =~ "Reporter :webhook configured but CLAUDE_WEBHOOK_URL not set"
    end

    test "expands {:webhook, opts} tuple properly" do
      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          {TestReporter, test_pid: self(), from: "direct"}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_received {:reported, ^event_data, opts}
      assert opts[:from] == "direct"
    end

    test "handles map-style opts by converting to keyword list" do
      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          {TestReporter, %{test_pid: self(), map_style: true}}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_received {:reported, ^event_data, opts}
      assert opts[:test_pid] == self()
      assert opts[:map_style] == true
    end

    test "warns about invalid reporter configuration" do
      config = %{
        reporters: [
          "invalid_string_reporter",
          123,
          {TestReporter, test_pid: self()}
        ]
      }

      log =
        capture_log(fn ->
          Reporter.dispatch(%{}, config)
        end)

      assert log =~ "Invalid reporter configuration: \"invalid_string_reporter\""
      assert log =~ "Invalid reporter configuration: 123"

      assert_received {:reported, _, _}
    end
  end

  describe "error handling" do
    test "logs reporter failures with {:error, reason}" do
      event_data = %{"hook_event_name" => "stop", "session_id" => "abc123"}

      config = %{
        reporters: [
          {FailingReporter, error_reason: "network timeout"},
          {TestReporter, test_pid: self()}
        ]
      }

      log =
        capture_log(fn ->
          Reporter.dispatch(event_data, config)
        end)

      assert log =~ "Reporter Claude.Hooks.ReporterTest.FailingReporter failed"
      assert log =~ "Reason: \"network timeout\""
      assert log =~ "Event: stop"

      assert_received {:reported, ^event_data, _}
    end

    test "logs reporter crashes with exception details" do
      event_data = %{"hook_event_name" => "pre_tool_use"}

      config = %{
        reporters: [
          {CrashingReporter, crash_message: "boom!"},
          {TestReporter, test_pid: self()}
        ]
      }

      log =
        capture_log(fn ->
          Reporter.dispatch(event_data, config)
        end)

      assert log =~ "Reporter Claude.Hooks.ReporterTest.CrashingReporter crashed"
      assert log =~ "** (RuntimeError) boom!"
      assert log =~ "Event: \"pre_tool_use\""

      assert_received {:reported, ^event_data, _}
    end

    test "logs when reporter returns unexpected value" do
      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          {InvalidReturnReporter, []},
          {TestReporter, test_pid: self()}
        ]
      }

      log =
        capture_log(fn ->
          Reporter.dispatch(event_data, config)
        end)

      assert log =~
               "Reporter Claude.Hooks.ReporterTest.InvalidReturnReporter returned unexpected value"

      assert log =~ "\"invalid return value\""
      assert log =~ "Expected :ok or {:error, reason}"

      assert_received {:reported, ^event_data, _}
    end

    test "logs when module doesn't implement report/2 callback" do
      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          {NonReporter, []},
          {TestReporter, test_pid: self()}
        ]
      }

      log =
        capture_log(fn ->
          Reporter.dispatch(event_data, config)
        end)

      assert log =~
               "Reporter Claude.Hooks.ReporterTest.NonReporter does not implement report/2 callback"

      assert_received {:reported, ^event_data, _}
    end

    test "multiple failing reporters all get logged" do
      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          {FailingReporter, error_reason: "error 1"},
          {CrashingReporter, crash_message: "crash 1"},
          {FailingReporter, error_reason: "error 2"},
          {TestReporter, test_pid: self()}
        ]
      }

      log =
        capture_log(fn ->
          Reporter.dispatch(event_data, config)
        end)

      assert log =~ "error 1"
      assert log =~ "crash 1"
      assert log =~ "error 2"

      assert_received {:reported, ^event_data, _}
    end
  end

  describe "event data handling" do
    test "passes complete event data to reporters" do
      event_data = %{
        "hook_event_name" => "post_tool_use",
        "tool_name" => "Write",
        "tool_input" => %{
          "file_path" => "/test/file.ex",
          "content" => "defmodule Test do\nend"
        },
        "tool_response" => %{
          "success" => true
        },
        "session_id" => "test-session-123",
        "transcript_path" => "/path/to/transcript.jsonl"
      }

      config = %{
        reporters: [
          {TestReporter, test_pid: self()}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_received {:reported, received_data, _}
      assert received_data == event_data
      assert received_data["tool_input"]["file_path"] == "/test/file.ex"
    end

    test "handles nil event data gracefully" do
      config = %{
        reporters: [
          {TestReporter, test_pid: self()}
        ]
      }

      Reporter.dispatch(nil, config)

      assert_received {:reported, nil, _}
    end

    test "each reporter receives independent copy of opts" do
      event_data = %{"hook_event_name" => "test"}

      config = %{
        reporters: [
          {TestReporter, test_pid: self(), shared: "value", unique: 1},
          {TestReporter, test_pid: self(), shared: "value", unique: 2}
        ]
      }

      Reporter.dispatch(event_data, config)

      assert_received {:reported, _, opts1}
      assert opts1[:unique] == 1

      assert_received {:reported, _, opts2}
      assert opts2[:unique] == 2

      assert opts1[:shared] == "value"
      assert opts2[:shared] == "value"
    end
  end

  describe "execution behavior" do
    test "reporter errors don't affect main process" do
      defmodule AsyncCrashReporter do
        @behaviour Claude.Hooks.Reporter

        @impl true
        def report(_event_data, opts) do
          test_pid = opts[:test_pid]

          Task.start(fn ->
            send(test_pid, :task_started)
            raise "async crash won't affect main process"
          end)

          :ok
        end
      end

      config = %{
        reporters: [
          {AsyncCrashReporter, test_pid: self()}
        ]
      }

      capture_log(fn ->
        assert Reporter.dispatch(%{}, config) == :ok
        assert_receive :task_started, 100
        refute_receive :any_other_message, 100
      end)

      assert Process.alive?(self())
    end

    test "reporters run synchronously in order" do
      defmodule SequentialReporter do
        @behaviour Claude.Hooks.Reporter

        @impl true
        def report(_event_data, opts) do
          send(opts[:test_pid], {:started, opts[:id], System.monotonic_time(:millisecond)})
          Process.sleep(20)
          send(opts[:test_pid], {:completed, opts[:id], System.monotonic_time(:millisecond)})
          :ok
        end
      end

      config = %{
        reporters: [
          {SequentialReporter, test_pid: self(), id: 1},
          {SequentialReporter, test_pid: self(), id: 2},
          {SequentialReporter, test_pid: self(), id: 3}
        ]
      }

      Reporter.dispatch(%{}, config)

      assert_receive {:started, 1, _start1}, 100
      assert_receive {:completed, 1, complete1}, 100
      assert_receive {:started, 2, start2}, 100
      assert_receive {:completed, 2, complete2}, 100
      assert_receive {:started, 3, start3}, 100
      assert_receive {:completed, 3, _complete3}, 100

      # Verify sequential execution: each reporter completes before the next starts
      assert complete1 <= start2
      assert complete2 <= start3
    end
  end
end
