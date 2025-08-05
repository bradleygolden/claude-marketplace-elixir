defmodule Claude.Hooks.Events.PreCompactTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.PreCompact

  describe "Input" do
    test "new/1 creates struct from map with manual trigger" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "PreCompact",
        "trigger" => "manual",
        "custom_instructions" => "Keep all test files"
      }

      input = PreCompact.Input.new(attrs)

      assert input.session_id == "test-123"
      assert input.transcript_path == "/path/to/transcript.jsonl"
      assert input.hook_event_name == "PreCompact"
      assert input.trigger == :manual
      assert input.custom_instructions == "Keep all test files"
    end

    test "new/1 creates struct from map with auto trigger" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "PreCompact",
        "trigger" => "auto",
        "custom_instructions" => ""
      }

      input = PreCompact.Input.new(attrs)

      assert input.trigger == :auto
      assert input.custom_instructions == ""
    end

    test "new/1 defaults hook_event_name if not provided" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "trigger" => "manual",
        "custom_instructions" => "Test"
      }

      input = PreCompact.Input.new(attrs)
      assert input.hook_event_name == "PreCompact"
    end

    test "from_json/1 parses valid JSON" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "hook_event_name": "PreCompact",
        "trigger": "manual",
        "custom_instructions": "Preserve important context"
      })

      {:ok, input} = PreCompact.Input.from_json(json)

      assert input.session_id == "test-123"
      assert input.trigger == :manual
      assert input.custom_instructions == "Preserve important context"
    end

    test "from_json/1 handles invalid JSON" do
      assert {:error, _} = PreCompact.Input.from_json("invalid json")
    end

    test "Jason.Encoder implementation encodes Input struct" do
      input = %PreCompact.Input{
        session_id: "test-123",
        transcript_path: "/path/to/transcript.jsonl",
        hook_event_name: "PreCompact",
        trigger: "auto",
        custom_instructions: ""
      }

      json = Jason.encode!(input)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-123"
      assert decoded["trigger"] == "auto"
      assert decoded["custom_instructions"] == ""
      refute Map.has_key?(decoded, "cwd")
    end
  end
end
