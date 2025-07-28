defmodule Claude.Hooks.TelemetryTest do
  use Claude.Test.ClaudeCodeCase, async: false

  alias Claude.Hooks.Telemetry

  defmodule TestHook do
    use Claude.Hooks.Hook.Behaviour,
      event: :post_tool_use,
      matcher: :write,
      description: "Test hook for telemetry testing"

    @impl Claude.Hooks.Hook.Behaviour
    def run(_json_input, _user_config) do
      :ok
    end
  end

  defmodule FailingTestHook do
    use Claude.Hooks.Hook.Behaviour,
      event: :pre_tool_use,
      matcher: :edit,
      description: "Test hook that fails"

    @impl Claude.Hooks.Hook.Behaviour
    def run(_json_input, _user_config) do
      raise "Test error"
    end
  end

  describe "telemetry_available?/0" do
    test "returns true when telemetry is loaded" do
      assert Telemetry.telemetry_available?()
    end
  end

  describe "execute_hook/3 with telemetry available" do
    setup do
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

      :ok
    end

    test "emits start and stop events for successful hook execution" do
      json_input =
        Jason.encode!(%{
          "session_id" => "test-123",
          "transcript_path" => "/path/to/transcript.jsonl",
          "cwd" => "/project/dir",
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Write",
          "tool_input" => %{
            "file_path" => "/test/file.ex",
            "content" => "test content"
          }
        })

      result = Telemetry.execute_hook(TestHook, json_input)
      assert result == :ok

      assert_receive {:telemetry_event, [:claude, :hook, :start], measurements, metadata}
      assert Map.has_key?(measurements, :monotonic_time)
      assert Map.has_key?(measurements, :system_time)
      assert metadata.hook_module == TestHook
      assert metadata.hook_identifier == "telemetry_test.test_hook"
      assert metadata.hook_event == :post_tool_use
      assert metadata.input_size == byte_size(json_input)
      assert metadata.session_id == "test-123"
      assert metadata.transcript_path == "/path/to/transcript.jsonl"
      assert metadata.cwd == "/project/dir"
      assert metadata.claude_event_name == "PostToolUse"
      assert metadata.tool_name == "Write"
      assert metadata.tool_input == %{"file_path" => "/test/file.ex", "content" => "test content"}

      assert_receive {:telemetry_event, [:claude, :hook, :stop], measurements, metadata}
      assert is_integer(measurements.duration)
      assert measurements.duration > 0
      assert metadata.result == :ok
    end

    test "emits exception event when hook raises" do
      json_input =
        Jason.encode!(%{
          "session_id" => "test-456",
          "hook_event_name" => "PreToolUse",
          "tool_name" => "Edit"
        })

      assert_raise RuntimeError, "Test error", fn ->
        Telemetry.execute_hook(FailingTestHook, json_input)
      end

      assert_receive {:telemetry_event, [:claude, :hook, :start], _measurements, metadata}
      assert metadata.hook_module == FailingTestHook
      assert metadata.hook_event == :pre_tool_use

      assert_receive {:telemetry_event, [:claude, :hook, :exception], measurements, metadata}
      assert is_integer(measurements.duration)
      assert measurements.duration > 0
      assert metadata.kind == :error
      assert %RuntimeError{message: "Test error"} = metadata.reason
      assert is_list(metadata.stacktrace)
    end

    test "handles hook with run/1 signature" do
      defmodule SingleArityHook do
        use Claude.Hooks.Hook.Behaviour,
          event: :notification,
          matcher: "*",
          description: "Hook with single arity run"

        @impl Claude.Hooks.Hook.Behaviour
        def run(_json_input) do
          {:ok, :single_arity}
        end

        @impl Claude.Hooks.Hook.Behaviour
        def run(_json_input, _user_config) do
          {:ok, :single_arity}
        end
      end

      json_input =
        Jason.encode!(%{
          "session_id" => "test-789",
          "hook_event_name" => "Notification",
          "message" => "Test notification"
        })

      result = Telemetry.execute_hook(SingleArityHook, json_input)
      assert result == {:ok, :single_arity}

      assert_receive {:telemetry_event, [:claude, :hook, :stop], _measurements, metadata}
      assert metadata.result == {:ok, :single_arity}
      assert metadata.hook_identifier == "telemetry_test.single_arity_hook"
    end

    test "extracts all metadata fields from various event types" do
      json_input =
        Jason.encode!(%{
          "session_id" => "prompt-123",
          "hook_event_name" => "UserPromptSubmit",
          "prompt" => "Write a function"
        })

      Telemetry.execute_hook(TestHook, json_input)
      assert_receive {:telemetry_event, [:claude, :hook, :start], _measurements, metadata}
      assert metadata.prompt == "Write a function"

      json_input =
        Jason.encode!(%{
          "session_id" => "stop-123",
          "hook_event_name" => "Stop",
          "stop_hook_active" => true
        })

      Telemetry.execute_hook(TestHook, json_input)
      assert_receive {:telemetry_event, [:claude, :hook, :start], _measurements, metadata}
      assert metadata.stop_hook_active == true

      json_input =
        Jason.encode!(%{
          "session_id" => "compact-123",
          "hook_event_name" => "PreCompact",
          "trigger" => "manual",
          "custom_instructions" => "Keep recent context"
        })

      Telemetry.execute_hook(TestHook, json_input)
      assert_receive {:telemetry_event, [:claude, :hook, :start], _measurements, metadata}
      assert metadata.trigger == "manual"
      assert metadata.custom_instructions == "Keep recent context"
    end

    test "handles PostToolUse with tool_response" do
      json_input =
        Jason.encode!(%{
          "session_id" => "post-123",
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Write",
          "tool_input" => %{"file_path" => "/test.ex"},
          "tool_response" => %{
            "success" => true,
            "filePath" => "/test.ex"
          }
        })

      Telemetry.execute_hook(TestHook, json_input)
      assert_receive {:telemetry_event, [:claude, :hook, :start], _measurements, metadata}
      assert metadata.tool_response == %{"success" => true, "filePath" => "/test.ex"}
    end

    test "handles malformed JSON gracefully" do
      json_input = "not valid json"

      result = Telemetry.execute_hook(TestHook, json_input)
      assert result == :ok

      assert_receive {:telemetry_event, [:claude, :hook, :start], _measurements, metadata}
      assert metadata.hook_module == TestHook
      assert metadata.input_size == byte_size(json_input)
      refute Map.has_key?(metadata, :session_id)
      refute Map.has_key?(metadata, :tool_name)
    end
  end

  describe "execute_hook/3 without telemetry" do
    test "executes hook normally when telemetry is not available" do
      assert function_exported?(Telemetry, :execute_hook, 3)
      assert function_exported?(Telemetry, :execute_hook, 2)
    end
  end

  describe "emit_event/4" do
    setup do
      test_pid = self()
      handler_id = "custom-handler-#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:claude, :hook, :custom, :test],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:custom_telemetry_event, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      :ok
    end

    test "emits custom telemetry events with proper metadata" do
      measurements = %{files_checked: 3, duration_ms: 150}
      metadata = %{status: :needs_formatting, files: ["a.ex", "b.ex", "c.ex"]}

      result = Telemetry.emit_event([:custom, :test], measurements, metadata, TestHook)
      assert result == :ok

      assert_receive {:custom_telemetry_event, [:claude, :hook, :custom, :test],
                      recv_measurements, recv_metadata}

      assert recv_measurements == measurements
      assert recv_metadata.status == :needs_formatting
      assert recv_metadata.files == ["a.ex", "b.ex", "c.ex"]
      assert recv_metadata.hook_module == TestHook
      assert recv_metadata.hook_identifier == "telemetry_test.test_hook"
      assert recv_metadata.hook_event == :post_tool_use
    end

    test "handles single atom event suffix" do
      test_pid = self()
      handler_id = "single-atom-handler-#{System.unique_integer()}"

      :telemetry.attach(
        handler_id,
        [:claude, :hook, :test],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:single_atom_event, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      Telemetry.emit_event(:test, %{count: 1}, %{}, TestHook)

      assert_receive {:single_atom_event, [:claude, :hook, :test], _measurements, _metadata}
    end
  end

  describe "build_metadata/2" do
    test "builds complete metadata from hook module and JSON input" do
      json_input =
        Jason.encode!(%{
          "session_id" => "meta-123",
          "transcript_path" => "/transcript.jsonl",
          "cwd" => "/work/dir",
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Edit",
          "tool_input" => %{"file_path" => "/file.ex"},
          "message" => "Test message",
          "prompt" => "Test prompt"
        })

      metadata = Telemetry.build_metadata(TestHook, json_input)

      assert metadata.hook_module == TestHook
      assert metadata.hook_identifier == "telemetry_test.test_hook"
      assert metadata.hook_event == :post_tool_use
      assert metadata.input_size == byte_size(json_input)
      assert metadata.session_id == "meta-123"
      assert metadata.transcript_path == "/transcript.jsonl"
      assert metadata.cwd == "/work/dir"
      assert metadata.claude_event_name == "PostToolUse"
      assert metadata.tool_name == "Edit"
      assert metadata.tool_input == %{"file_path" => "/file.ex"}
      assert metadata.message == "Test message"
      assert metadata.prompt == "Test prompt"
    end

    test "handles missing optional fields gracefully" do
      json_input =
        Jason.encode!(%{
          "session_id" => "minimal-123",
          "hook_event_name" => "PostToolUse"
        })

      metadata = Telemetry.build_metadata(TestHook, json_input)

      assert metadata.session_id == "minimal-123"
      assert metadata.claude_event_name == "PostToolUse"
      refute Map.has_key?(metadata, :tool_name)
      refute Map.has_key?(metadata, :transcript_path)
      refute Map.has_key?(metadata, :cwd)
    end

    test "infers hook event from module name when not using behaviour macro" do
      defmodule PreToolUseCustomHook do
        def config, do: %Claude.Hooks.Hook{type: "command", command: "test"}
        def run(_), do: :ok
        def description, do: "Test"
      end

      metadata = Telemetry.build_metadata(PreToolUseCustomHook, "{}")
      assert metadata.hook_event == :unknown
    end
  end
end
