defmodule Claude.CLI.Hooks.RunTelemetryTest do
  use Claude.Test.ClaudeCodeCase, async: false

  alias Claude.CLI.Hooks.Run

  defmodule TestHookForAutoTelemetry do
    use Claude.Hooks.Hook.Behaviour,
      event: :post_tool_use,
      matcher: :write,
      description: "Test hook for automatic telemetry"

    @impl Claude.Hooks.Hook.Behaviour
    def run(json_input, _user_config) do
      case Jason.decode(json_input) do
        {:ok, _data} -> :ok
        {:error, _} -> {:error, :invalid_json}
      end
    end
  end

  describe "automatic telemetry in CLI hook runner" do
    setup do
      Mimic.stub(Claude.Hooks.Registry, :all_hooks, fn ->
        [{__MODULE__.TestHookForAutoTelemetry, %{}}]
      end)

      Mimic.stub(Claude.Hooks.Registry, :find_by_identifier, fn identifier ->
        if identifier == "claude.cli.hooks.run_telemetry_test.test_hook_for_auto_telemetry" do
          __MODULE__.TestHookForAutoTelemetry
        else
          nil
        end
      end)

      test_pid = self()
      handler_id = "test-auto-telemetry-#{System.unique_integer()}"

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

      on_exit(fn ->
        :telemetry.detach(handler_id)
      end)

      :ok
    end

    test "hooks automatically emit telemetry events when run through CLI" do
      json_input =
        Jason.encode!(%{
          "session_id" => "auto-123",
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Write",
          "tool_input" => %{"file_path" => "/test.ex"}
        })

      Mimic.expect(IO, :read, fn :stdio, :eof -> json_input end)

      Run.run(["claude.cli.hooks.run_telemetry_test.test_hook_for_auto_telemetry"])

      assert_receive {:telemetry_event, [:claude, :hook, :start], measurements, metadata}
      assert Map.has_key?(measurements, :monotonic_time)
      assert metadata.hook_module == __MODULE__.TestHookForAutoTelemetry

      assert metadata.hook_identifier ==
               "claude.cli.hooks.run_telemetry_test.test_hook_for_auto_telemetry"

      assert metadata.session_id == "auto-123"
      assert metadata.tool_name == "Write"

      assert_receive {:telemetry_event, [:claude, :hook, :stop], measurements, metadata}
      assert is_integer(measurements.duration)
      assert measurements.duration > 0
      assert metadata.result == :ok
    end

    test "CLI runner works without telemetry" do
      Mimic.stub(Claude.Hooks.Telemetry, :telemetry_available?, fn -> false end)

      json_input =
        Jason.encode!(%{
          "session_id" => "no-telemetry-123",
          "hook_event_name" => "PostToolUse"
        })

      Mimic.expect(IO, :read, fn :stdio, :eof -> json_input end)

      Run.run(["claude.cli.hooks.run_telemetry_test.test_hook_for_auto_telemetry"])

      refute_receive {:telemetry_event, _, _, _}, 100
    end
  end
end
