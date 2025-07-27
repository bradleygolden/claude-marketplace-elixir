defmodule Claude.Hooks.Events.SubagentStopTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.SubagentStop

  describe "Input" do
    test "new/1 creates struct from map" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "SubagentStop",
        "stop_hook_active" => true
      }

      input = SubagentStop.Input.new(attrs)

      assert input.session_id == "test-123"
      assert input.transcript_path == "/path/to/transcript.jsonl"
      assert input.hook_event_name == "SubagentStop"
      assert input.stop_hook_active == true
    end

    test "new/1 defaults stop_hook_active to false" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "SubagentStop"
      }

      input = SubagentStop.Input.new(attrs)
      assert input.stop_hook_active == false
    end

    test "new/1 defaults hook_event_name if not provided" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl"
      }

      input = SubagentStop.Input.new(attrs)
      assert input.hook_event_name == "SubagentStop"
    end

    test "from_json/1 parses valid JSON" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "hook_event_name": "SubagentStop",
        "stop_hook_active": false
      })

      {:ok, input} = SubagentStop.Input.from_json(json)

      assert input.session_id == "test-123"
      assert input.stop_hook_active == false
    end

    test "from_json/1 handles invalid JSON" do
      assert {:error, _} = SubagentStop.Input.from_json("invalid json")
    end

    test "Jason.Encoder implementation encodes Input struct" do
      input = %SubagentStop.Input{
        session_id: "test-123",
        transcript_path: "/path/to/transcript.jsonl",
        hook_event_name: "SubagentStop",
        stop_hook_active: true
      }

      json = Jason.encode!(input)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-123"
      assert decoded["stop_hook_active"] == true
      # Note: SubagentStop events don't have cwd field
      refute Map.has_key?(decoded, "cwd")
    end
  end

  describe "Output" do
    test "Output has same interface as Stop.Output" do
      # SubagentStop.Output has the same interface as Stop.Output
      output = SubagentStop.Output.allow()
      assert %Claude.Hooks.Events.SubagentStop.Output{} = output
    end

    test "allow/0 creates allow output" do
      output = SubagentStop.Output.allow()

      assert output.continue == true
      assert output.decision == nil
      assert output.reason == nil
    end

    test "block/1 creates block decision output" do
      output = SubagentStop.Output.block("Subagent task incomplete")

      assert output.continue == true
      assert output.decision == :block
      assert output.reason == "Subagent task incomplete"
    end

    test "output can be encoded to JSON string" do
      output = SubagentStop.Output.block("Still processing")
      json = Jason.encode!(output)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == true
      assert decoded["decision"] == "block"
      assert decoded["reason"] == "Still processing"
    end
  end
end