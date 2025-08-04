defmodule Claude.Hooks.Events.CommonTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.Common
  alias Claude.Hooks.Events

  describe "parse_hook_input/1" do
    test "routes to PreToolUse for PreToolUse event" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "PreToolUse",
        "tool_name": "Write",
        "tool_input": {"file_path": "/test.ex", "content": "test"}
      })

      {:ok, event} = Common.parse_hook_input(json)
      assert %Events.PreToolUse.Input{} = event
      assert event.tool_name == "Write"
    end

    test "routes to PostToolUse for PostToolUse event" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "PostToolUse",
        "tool_name": "Write",
        "tool_input": {"file_path": "/test.ex", "content": "test"},
        "tool_response": {"success": true}
      })

      {:ok, event} = Common.parse_hook_input(json)
      assert %Events.PostToolUse.Input{} = event
      assert event.tool_response["success"] == true
    end

    test "routes to Notification for Notification event" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "Notification",
        "message": "Test notification"
      })

      {:ok, event} = Common.parse_hook_input(json)
      assert %Events.Notification.Input{} = event
      assert event.message == "Test notification"
    end

    test "routes to UserPromptSubmit for UserPromptSubmit event" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "UserPromptSubmit",
        "prompt": "Test prompt"
      })

      {:ok, event} = Common.parse_hook_input(json)
      assert %Events.UserPromptSubmit.Input{} = event
      assert event.prompt == "Test prompt"
    end

    test "routes to Stop for Stop event" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "hook_event_name": "Stop",
        "stop_hook_active": true
      })

      {:ok, event} = Common.parse_hook_input(json)
      assert %Events.Stop.Input{} = event
      assert event.stop_hook_active == true
    end

    test "routes to SubagentStop for SubagentStop event" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "hook_event_name": "SubagentStop",
        "stop_hook_active": false
      })

      {:ok, event} = Common.parse_hook_input(json)
      assert %Events.SubagentStop.Input{} = event
      assert event.stop_hook_active == false
    end

    test "routes to PreCompact for PreCompact event" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "hook_event_name": "PreCompact",
        "trigger": "manual",
        "custom_instructions": "Test"
      })

      {:ok, event} = Common.parse_hook_input(json)
      assert %Events.PreCompact.Input{} = event
      assert event.trigger == :manual
    end

    test "returns error for unknown event type" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "hook_event_name": "UnknownEvent"
      })

      assert {:error, "Unknown hook event name: \"UnknownEvent\""} = Common.parse_hook_input(json)
    end

    test "returns error for invalid JSON" do
      assert {:error, %Jason.DecodeError{}} = Common.parse_hook_input("not json")
    end

    test "returns error for non-string input" do
      assert {:error, _} = Common.parse_hook_input(123)
      assert {:error, _} = Common.parse_hook_input(nil)
      assert {:error, _} = Common.parse_hook_input(%{})
    end
  end

  describe "SimpleOutput" do
    test "success/0 creates exit code 0 output" do
      output = Common.SimpleOutput.success()

      assert output.exit_code == 0
      assert output.stdout == nil
      assert output.stderr == nil
    end

    test "success/1 creates exit code 0 output with stdout" do
      output = Common.SimpleOutput.success("Operation completed")

      assert output.exit_code == 0
      assert output.stdout == "Operation completed"
      assert output.stderr == nil
    end

    test "error/1 creates exit code 1 output with stderr" do
      output = Common.SimpleOutput.error("Something went wrong")

      assert output.exit_code == 1
      assert output.stdout == nil
      assert output.stderr == "Something went wrong"
    end

    test "block/1 creates exit code 2 output with stderr" do
      output = Common.SimpleOutput.block("Operation blocked")

      assert output.exit_code == 2
      assert output.stdout == nil
      assert output.stderr == "Operation blocked"
    end

    test "output can be encoded to JSON string" do
      output = Common.SimpleOutput.success("Done")
      json = Jason.encode!(output)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["exitCode"] == 0
      assert decoded["stdout"] == "Done"
    end

    test "write_and_exit/1 writes JSON to stdout (mocked)" do
      output = Common.SimpleOutput.success("Test")

      json = Jason.encode!(output)
      assert json =~ ~s("exitCode":0)
      assert json =~ ~s("stdout":"Test")
    end

    test "Jason.Encoder implementation converts to camelCase" do
      output = %Common.SimpleOutput{
        exit_code: 1,
        stdout: "output",
        stderr: "error"
      }

      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded["exitCode"] == 1
      assert decoded["stdout"] == "output"
      assert decoded["stderr"] == "error"
    end

    test "Jason.Encoder filters nil values" do
      output = Common.SimpleOutput.success()
      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded == %{"exitCode" => 0}
      refute Map.has_key?(decoded, "stdout")
      refute Map.has_key?(decoded, "stderr")
    end
  end
end
