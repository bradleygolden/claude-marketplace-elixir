defmodule Claude.Hooks.EventsTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events
  alias Claude.Hooks.Events.Common

  describe "PreToolUse" do
    test "creates struct from map" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "PreToolUse",
        "tool_name" => "Edit",
        "tool_input" => %{"file_path" => "/file.ex"}
      }

      event = Events.PreToolUse.Input.new(attrs)

      assert event.session_id == "abc123"
      assert event.transcript_path == "/path/to/transcript.jsonl"
      assert event.cwd == "/project"
      assert event.hook_event_name == "PreToolUse"
      assert event.tool_name == "Edit"
      assert %Claude.Hooks.ToolInputs.Edit{file_path: "/file.ex"} = event.tool_input
    end

    test "parses from JSON" do
      json = ~s({
        "session_id": "abc123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "PreToolUse",
        "tool_name": "Edit",
        "tool_input": {"file_path": "/file.ex"}
      })

      assert {:ok, event} = Events.PreToolUse.Input.from_json(json)
      assert event.tool_name == "Edit"
      assert event.tool_input.file_path == "/file.ex"
    end

    test "handles missing optional fields" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "tool_name" => "Edit"
      }

      event = Events.PreToolUse.Input.new(attrs)
      assert event.hook_event_name == "PreToolUse"
      assert %Claude.Hooks.ToolInputs.Edit{file_path: nil} = event.tool_input
    end

    test "returns raw map for unknown tools" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "tool_name" => "UnknownTool",
        "tool_input" => %{"some" => "data", "other" => "value"}
      }

      event = Events.PreToolUse.Input.new(attrs)
      assert event.tool_name == "UnknownTool"
      assert event.tool_input == %{"some" => "data", "other" => "value"}
    end
  end

  describe "PostToolUse" do
    test "creates struct from map with tool response" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "PostToolUse",
        "tool_name" => "Write",
        "tool_input" => %{"file_path" => "/file.ex", "content" => "defmodule Test do\nend"},
        "tool_response" => %{"filePath" => "/file.ex", "success" => true}
      }

      event = Events.PostToolUse.Input.new(attrs)

      assert event.tool_name == "Write"
      assert event.tool_response["success"] == true
    end
  end

  describe "Notification" do
    test "creates struct from map" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "Notification",
        "message" => "Claude needs your permission to use Bash"
      }

      event = Events.Notification.Input.new(attrs)
      assert event.message == "Claude needs your permission to use Bash"
    end
  end

  describe "UserPromptSubmit" do
    test "creates struct from map" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "UserPromptSubmit",
        "prompt" => "Write a function to calculate factorial"
      }

      event = Events.UserPromptSubmit.Input.new(attrs)
      assert event.prompt == "Write a function to calculate factorial"
    end
  end

  describe "Stop" do
    test "creates struct from map" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "Stop",
        "stop_hook_active" => true
      }

      event = Events.Stop.Input.new(attrs)
      assert event.stop_hook_active == true
    end

    test "defaults stop_hook_active to false" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "Stop"
      }

      event = Events.Stop.Input.new(attrs)
      assert event.stop_hook_active == false
    end
  end

  describe "PreCompact" do
    test "creates struct with manual trigger" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "PreCompact",
        "trigger" => "manual",
        "custom_instructions" => "Keep error handling code"
      }

      event = Events.PreCompact.Input.new(attrs)
      assert event.trigger == :manual
      assert event.custom_instructions == "Keep error handling code"
    end

    test "creates struct with auto trigger" do
      attrs = %{
        "session_id" => "abc123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "PreCompact",
        "trigger" => "auto"
      }

      event = Events.PreCompact.Input.new(attrs)
      assert event.trigger == :auto
      assert event.custom_instructions == ""
    end
  end

  describe "parse_hook_input/1" do
    test "parses PreToolUse event" do
      json = ~s({
        "hook_event_name": "PreToolUse",
        "session_id": "abc123",
        "tool_name": "Edit"
      })

      assert {:ok, event} = Common.parse_hook_input(json)
      assert %Events.PreToolUse.Input{} = event
      assert event.tool_name == "Edit"
    end

    test "parses PostToolUse event" do
      json = ~s({
        "hook_event_name": "PostToolUse",
        "session_id": "abc123",
        "tool_name": "Write",
        "tool_response": {"success": true}
      })

      assert {:ok, event} = Common.parse_hook_input(json)
      assert %Events.PostToolUse.Input{} = event
      assert event.tool_response["success"] == true
    end

    test "parses Notification event" do
      json = ~s({
        "hook_event_name": "Notification",
        "session_id": "abc123",
        "message": "Test notification"
      })

      assert {:ok, event} = Common.parse_hook_input(json)
      assert %Events.Notification.Input{} = event
      assert event.message == "Test notification"
    end

    test "parses UserPromptSubmit event" do
      json = ~s({
        "hook_event_name": "UserPromptSubmit",
        "session_id": "abc123",
        "prompt": "Test prompt"
      })

      assert {:ok, event} = Common.parse_hook_input(json)
      assert %Events.UserPromptSubmit.Input{} = event
      assert event.prompt == "Test prompt"
    end

    test "parses Stop event" do
      json = ~s({
        "hook_event_name": "Stop",
        "session_id": "abc123",
        "stop_hook_active": false
      })

      assert {:ok, event} = Common.parse_hook_input(json)
      assert %Events.Stop.Input{} = event
      assert event.stop_hook_active == false
    end

    test "parses SubagentStop event" do
      json = ~s({
        "hook_event_name": "SubagentStop",
        "session_id": "abc123",
        "stop_hook_active": true
      })

      assert {:ok, event} = Common.parse_hook_input(json)
      assert %Events.SubagentStop.Input{} = event
      assert event.stop_hook_active == true
    end

    test "parses PreCompact event" do
      json = ~s({
        "hook_event_name": "PreCompact",
        "session_id": "abc123",
        "trigger": "manual"
      })

      assert {:ok, event} = Common.parse_hook_input(json)
      assert %Events.PreCompact.Input{} = event
      assert event.trigger == :manual
    end

    test "returns error for unknown event" do
      json = ~s({
        "hook_event_name": "UnknownEvent",
        "session_id": "abc123"
      })

      assert {:error, "Unknown hook event name: \"UnknownEvent\""} = Common.parse_hook_input(json)
    end

    test "returns error for invalid JSON" do
      assert {:error, _} = Common.parse_hook_input("invalid json")
    end
  end

  describe "Jason.Encoder" do
    test "encodes PreToolUse to JSON" do
      event = %Events.PreToolUse.Input{
        session_id: "abc123",
        tool_name: "Edit",
        tool_input: %{"file_path" => "/test.ex"}
      }

      assert {:ok, json} = Jason.encode(event)
      assert json =~ ~s("session_id":"abc123")
      assert json =~ ~s("tool_name":"Edit")
    end

    test "encodes PostToolUse to JSON" do
      event = %Events.PostToolUse.Input{
        session_id: "abc123",
        tool_name: "Write",
        tool_response: %{"success" => true}
      }

      assert {:ok, json} = Jason.encode(event)
      assert json =~ ~s("tool_response":{"success":true})
    end

    test "encodes PreCompact with atom trigger to JSON" do
      event = %Events.PreCompact.Input{
        session_id: "abc123",
        trigger: :manual,
        custom_instructions: "Keep errors"
      }

      assert {:ok, json} = Jason.encode(event)
      assert json =~ ~s("trigger":"manual")
      assert json =~ ~s("custom_instructions":"Keep errors")
    end
  end
end
