defmodule Claude.Hooks.Events.StopTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.Stop

  describe "Input" do
    test "new/1 creates struct from map" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "Stop",
        "stop_hook_active" => true
      }

      input = Stop.Input.new(attrs)

      assert input.session_id == "test-123"
      assert input.transcript_path == "/path/to/transcript.jsonl"
      assert input.hook_event_name == "Stop"
      assert input.stop_hook_active == true
    end

    test "new/1 defaults stop_hook_active to false" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "hook_event_name" => "Stop"
      }

      input = Stop.Input.new(attrs)
      assert input.stop_hook_active == false
    end

    test "new/1 defaults hook_event_name if not provided" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl"
      }

      input = Stop.Input.new(attrs)
      assert input.hook_event_name == "Stop"
    end

    test "from_json/1 parses valid JSON" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "hook_event_name": "Stop",
        "stop_hook_active": true
      })

      {:ok, input} = Stop.Input.from_json(json)

      assert input.session_id == "test-123"
      assert input.stop_hook_active == true
    end

    test "from_json/1 handles invalid JSON" do
      assert {:error, _} = Stop.Input.from_json("invalid json")
    end

    test "Jason.Encoder implementation encodes Input struct" do
      input = %Stop.Input{
        session_id: "test-123",
        transcript_path: "/path/to/transcript.jsonl",
        hook_event_name: "Stop",
        stop_hook_active: false
      }

      json = Jason.encode!(input)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-123"
      assert decoded["stop_hook_active"] == false
      # Note: Stop events don't have cwd field
      refute Map.has_key?(decoded, "cwd")
    end
  end

  describe "Output" do
    test "allow/0 creates allow output" do
      output = Stop.Output.allow()

      assert output.continue == true
      assert output.decision == nil
      assert output.reason == nil
    end

    test "block/1 creates block decision output" do
      output = Stop.Output.block("Tests are still running")

      assert output.continue == true
      assert output.decision == :block
      assert output.reason == "Tests are still running"
    end

    test "output can be encoded to JSON string" do
      output = Stop.Output.block("Build in progress")
      json = Jason.encode!(output)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == true
      assert decoded["decision"] == "block"
      assert decoded["reason"] == "Build in progress"
    end

    test "Jason.Encoder implementation converts snake_case to camelCase" do
      output = %Stop.Output{
        continue: false,
        stop_reason: "Force stop",
        suppress_output: true,
        decision: :block,
        reason: "Cannot stop yet"
      }

      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == false
      assert decoded["stopReason"] == "Force stop"
      assert decoded["suppressOutput"] == true
      assert decoded["decision"] == "block"
      assert decoded["reason"] == "Cannot stop yet"
    end

    test "Jason.Encoder filters nil values" do
      output = Stop.Output.allow()
      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded == %{"continue" => true, "suppressOutput" => false}
      refute Map.has_key?(decoded, "decision")
      refute Map.has_key?(decoded, "reason")
    end
  end
end