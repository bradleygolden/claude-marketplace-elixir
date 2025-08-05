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
end
