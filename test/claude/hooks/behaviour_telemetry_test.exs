defmodule Claude.Hooks.BehaviourTelemetryTest do
  use Claude.Test.ClaudeCodeCase, async: false

  defmodule TelemetryHook do
    use Claude.Hooks.Hook.Behaviour,
      event: :post_tool_use,
      matcher: [:write, :edit],
      description: "Hook that emits telemetry"

    @impl Claude.Hooks.Hook.Behaviour
    def run(json_input, _user_config) do
      case Jason.decode(json_input) do
        {:ok, %{"tool_name" => "Write"}} ->
          emit_telemetry(:processing_write, %{bytes: 100}, %{file_type: :elixir})
          :ok

        {:ok, %{"tool_name" => "Edit"}} ->
          emit_telemetry([:validation, :failed], %{errors: 3}, %{reason: :syntax_error})
          {:error, :validation_failed}

        _ ->
          emit_telemetry(:unknown_tool)
          :ok
      end
    end
  end

  describe "emit_telemetry/3 in hooks" do
    setup do
      test_pid = self()
      handler_id = "test-behaviour-telemetry-#{System.unique_integer()}"

      :telemetry.attach_many(
        handler_id,
        [
          [:claude, :hook, :processing_write],
          [:claude, :hook, :validation, :failed],
          [:claude, :hook, :unknown_tool]
        ],
        fn event, measurements, metadata, _config ->
          send(test_pid, {:custom_event, event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      :ok
    end

    test "emit_telemetry works with single atom event" do
      json_input = Jason.encode!(%{"tool_name" => "Unknown"})

      assert :ok = TelemetryHook.run(json_input)

      assert_receive {:custom_event, [:claude, :hook, :unknown_tool], measurements, metadata}
      assert measurements == %{}
      assert metadata.hook_module == TelemetryHook
      assert metadata.hook_identifier == "behaviour_telemetry_test.telemetry_hook"
      assert metadata.hook_event == :post_tool_use
    end

    test "emit_telemetry works with measurements and metadata" do
      json_input = Jason.encode!(%{"tool_name" => "Write"})

      assert :ok = TelemetryHook.run(json_input)

      assert_receive {:custom_event, [:claude, :hook, :processing_write], measurements, metadata}
      assert measurements == %{bytes: 100}
      assert metadata.file_type == :elixir
      assert metadata.hook_module == TelemetryHook
    end

    test "emit_telemetry works with nested event names" do
      json_input = Jason.encode!(%{"tool_name" => "Edit"})

      assert {:error, :validation_failed} = TelemetryHook.run(json_input)

      assert_receive {:custom_event, [:claude, :hook, :validation, :failed], measurements,
                      metadata}

      assert measurements == %{errors: 3}
      assert metadata.reason == :syntax_error
      assert metadata.hook_module == TelemetryHook
    end

    test "emit_telemetry is available in all hooks using the behaviour" do
      defmodule AnotherHook do
        use Claude.Hooks.Hook.Behaviour,
          event: :pre_tool_use,
          matcher: :bash,
          description: "Another test hook"
      end

      assert function_exported?(AnotherHook, :emit_telemetry, 1)
      assert function_exported?(AnotherHook, :emit_telemetry, 2)
      assert function_exported?(AnotherHook, :emit_telemetry, 3)
    end
  end

  describe "emit_telemetry/3 without telemetry" do
    test "emit_telemetry is still defined and returns :ok" do
      defmodule NoTelemetryHook do
        use Claude.Hooks.Hook.Behaviour,
          event: :notification,
          matcher: "*",
          description: "Hook without telemetry"

        @impl Claude.Hooks.Hook.Behaviour
        def run(_json_input, _user_config) do
          result = emit_telemetry(:test_event, %{value: 42}, %{status: :ok})
          {:ok, result}
        end
      end

      json_input = Jason.encode!(%{})
      assert {:ok, :ok} = NoTelemetryHook.run(json_input)
    end
  end

  describe "hook metadata functions" do
    test "hooks expose their metadata through functions" do
      assert TelemetryHook.__hook_event__() == :post_tool_use
      assert TelemetryHook.__hook_matcher__() == "Write|Edit"
      assert TelemetryHook.__hook_identifier__() == "behaviour_telemetry_test.telemetry_hook"
    end
  end
end
