defmodule Claude.Hooks.Events.NotificationTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.Notification

  describe "Input" do
    test "new/1 creates struct from map" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "Notification",
        "message" => "Claude needs your permission to use Bash"
      }

      input = Notification.Input.new(attrs)

      assert input.session_id == "test-123"
      assert input.transcript_path == "/path/to/transcript.jsonl"
      assert input.cwd == "/project"
      assert input.hook_event_name == "Notification"
      assert input.message == "Claude needs your permission to use Bash"
    end

    test "new/1 defaults hook_event_name if not provided" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "message" => "Test notification"
      }

      input = Notification.Input.new(attrs)
      assert input.hook_event_name == "Notification"
    end

    test "from_json/1 parses valid JSON" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "Notification",
        "message": "Claude is waiting for your input"
      })

      {:ok, input} = Notification.Input.from_json(json)

      assert input.session_id == "test-123"
      assert input.message == "Claude is waiting for your input"
    end

    test "from_json/1 handles invalid JSON" do
      assert {:error, _} = Notification.Input.from_json("invalid json")
    end

    test "Jason.Encoder implementation encodes Input struct" do
      input = %Notification.Input{
        session_id: "test-123",
        transcript_path: "/path/to/transcript.jsonl",
        cwd: "/project",
        hook_event_name: "Notification",
        message: "Test message"
      }

      json = Jason.encode!(input)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-123"
      assert decoded["message"] == "Test message"
      assert decoded["cwd"] == "/project"
    end
  end

  describe "Output" do
    test "Output is aliased to Common.SimpleOutput" do
      # Notification.Output should be Common.SimpleOutput
      output = Notification.Output.success("Logged")
      assert %Claude.Hooks.Events.Common.SimpleOutput{} = output
    end

    test "success/0 creates success output" do
      output = Notification.Output.success()

      assert output.exit_code == 0
      assert output.stdout == nil
      assert output.stderr == nil
    end

    test "success/1 creates success output with message" do
      output = Notification.Output.success("Notification received")

      assert output.exit_code == 0
      assert output.stdout == "Notification received"
      assert output.stderr == nil
    end

    test "error/1 creates error output" do
      output = Notification.Output.error("Failed to process")

      assert output.exit_code == 1
      assert output.stdout == nil
      assert output.stderr == "Failed to process"
    end

    test "block/1 creates blocking output" do
      output = Notification.Output.block("Cannot proceed")

      assert output.exit_code == 2
      assert output.stdout == nil
      assert output.stderr == "Cannot proceed"
    end

    test "output can be encoded to JSON string" do
      output = Notification.Output.success("Logged notification")
      json = Jason.encode!(output)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["exitCode"] == 0
      assert decoded["stdout"] == "Logged notification"
    end

    test "Jason.Encoder filters nil values" do
      output = Notification.Output.success()
      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded == %{"exitCode" => 0}
      refute Map.has_key?(decoded, "stdout")
      refute Map.has_key?(decoded, "stderr")
    end
  end
end