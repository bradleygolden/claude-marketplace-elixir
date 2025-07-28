defmodule Claude.Hooks.Telemetry.DefaultHandlerTest do
  use Claude.Test.ClaudeCodeCase, async: false
  import ExUnit.CaptureLog

  alias Claude.Hooks.Telemetry
  alias Claude.Hooks.Telemetry.DefaultHandler

  defmodule TestHook do
    use Claude.Hooks.Hook.Behaviour,
      event: :post_tool_use,
      matcher: :write,
      description: "Test hook"

    @impl Claude.Hooks.Hook.Behaviour
    def run(_json_input, _user_config) do
      :ok
    end
  end

  defmodule ErrorHook do
    use Claude.Hooks.Hook.Behaviour,
      event: :pre_tool_use,
      matcher: :edit,
      description: "Error hook"

    @impl Claude.Hooks.Hook.Behaviour
    def run(_json_input, _user_config) do
      raise "Test error"
    end
  end

  describe "attach_default_handlers/0" do
    setup do
      on_exit(fn -> DefaultHandler.detach_default_handlers() end)
      :ok
    end

    test "attaches handlers successfully" do
      assert :ok = DefaultHandler.attach_default_handlers()
      assert DefaultHandler.handlers_attached?()
    end

    test "returns error when handlers already attached" do
      assert :ok = DefaultHandler.attach_default_handlers()
      assert {:error, :already_attached} = DefaultHandler.attach_default_handlers()
    end

    test "handlers log start events at debug level" do
      DefaultHandler.attach_default_handlers()

      json_input =
        Jason.encode!(%{
          "session_id" => "test-123",
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Write"
        })

      log =
        capture_log([level: :debug], fn ->
          Telemetry.execute_hook(TestHook, json_input)
        end)

      assert log =~ "Hook starting"
      assert log =~ "hook: telemetry.default_handler_test.test_hook"
      assert log =~ "event: :post_tool_use"
      assert log =~ "tool: \"Write\""
      assert log =~ "session: \"test-123\""
    end

    test "handlers log stop events with duration" do
      DefaultHandler.attach_default_handlers()

      json_input =
        Jason.encode!(%{
          "session_id" => "test-456",
          "hook_event_name" => "PostToolUse"
        })

      log =
        capture_log([level: :debug], fn ->
          Telemetry.execute_hook(TestHook, json_input)
        end)

      assert log =~ "Hook completed"
      assert log =~ "duration_ms:"
      assert log =~ "result: :ok"
    end

    test "handlers log exception events at error level" do
      DefaultHandler.attach_default_handlers()

      json_input =
        Jason.encode!(%{
          "session_id" => "error-123",
          "hook_event_name" => "PreToolUse",
          "tool_name" => "Edit"
        })

      log =
        capture_log([level: :error], fn ->
          assert_raise RuntimeError, fn ->
            Telemetry.execute_hook(ErrorHook, json_input)
          end
        end)

      assert log =~ "Hook failed"
      assert log =~ "hook: telemetry.default_handler_test.error_hook"
      assert log =~ "event: :pre_tool_use"
      assert log =~ "tool: \"Edit\""
      assert log =~ "error: ** (RuntimeError) Test error"
    end

    test "debug logs are not shown at info level" do
      DefaultHandler.attach_default_handlers()

      json_input =
        Jason.encode!(%{
          "session_id" => "test-789",
          "hook_event_name" => "PostToolUse"
        })

      log =
        capture_log([level: :info], fn ->
          Telemetry.execute_hook(TestHook, json_input)
        end)

      refute log =~ "Hook starting"
      refute log =~ "Hook completed"
    end
  end

  describe "detach_default_handlers/0" do
    test "detaches all handlers" do
      DefaultHandler.attach_default_handlers()
      assert DefaultHandler.handlers_attached?()

      assert :ok = DefaultHandler.detach_default_handlers()
      refute DefaultHandler.handlers_attached?()
    end

    test "returns ok even if handlers not attached" do
      refute DefaultHandler.handlers_attached?()
      assert :ok = DefaultHandler.detach_default_handlers()
    end
  end

  describe "handlers_attached?/0" do
    setup do
      on_exit(fn -> DefaultHandler.detach_default_handlers() end)
      :ok
    end

    test "returns false when no handlers attached" do
      refute DefaultHandler.handlers_attached?()
    end

    test "returns true when all handlers attached" do
      DefaultHandler.attach_default_handlers()
      assert DefaultHandler.handlers_attached?()
    end

    test "returns false when only some handlers attached" do
      :telemetry.attach(
        "claude-hooks-default-start",
        [:claude, :hook, :start],
        fn _, _, _, _ -> :ok end,
        nil
      )

      refute DefaultHandler.handlers_attached?()
    end
  end

  describe "integration with optional telemetry" do
    test "module is available even without telemetry" do
      assert Code.ensure_loaded?(DefaultHandler)
    end

    test "functions are defined" do
      assert function_exported?(DefaultHandler, :attach_default_handlers, 0)
      assert function_exported?(DefaultHandler, :detach_default_handlers, 0)
      assert function_exported?(DefaultHandler, :handlers_attached?, 0)
    end
  end
end
