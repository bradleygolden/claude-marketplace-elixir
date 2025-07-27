defmodule Claude.Hooks.Events.UserPromptSubmitTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.UserPromptSubmit

  describe "Input" do
    test "new/1 creates struct from map" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "UserPromptSubmit",
        "prompt" => "Write a function to calculate factorial"
      }

      input = UserPromptSubmit.Input.new(attrs)

      assert input.session_id == "test-123"
      assert input.transcript_path == "/path/to/transcript.jsonl"
      assert input.cwd == "/project"
      assert input.hook_event_name == "UserPromptSubmit"
      assert input.prompt == "Write a function to calculate factorial"
    end

    test "new/1 defaults hook_event_name if not provided" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "prompt" => "Test prompt"
      }

      input = UserPromptSubmit.Input.new(attrs)
      assert input.hook_event_name == "UserPromptSubmit"
    end

    test "from_json/1 parses valid JSON" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "UserPromptSubmit",
        "prompt": "Explain the code in this file"
      })

      {:ok, input} = UserPromptSubmit.Input.from_json(json)

      assert input.session_id == "test-123"
      assert input.prompt == "Explain the code in this file"
    end

    test "from_json/1 handles invalid JSON" do
      assert {:error, _} = UserPromptSubmit.Input.from_json("invalid json")
    end

    test "Jason.Encoder implementation encodes Input struct" do
      input = %UserPromptSubmit.Input{
        session_id: "test-123",
        transcript_path: "/path/to/transcript.jsonl",
        cwd: "/project",
        hook_event_name: "UserPromptSubmit",
        prompt: "Test prompt"
      }

      json = Jason.encode!(input)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-123"
      assert decoded["prompt"] == "Test prompt"
    end
  end

  describe "Output" do
    test "allow/0 creates allow output" do
      output = UserPromptSubmit.Output.allow()

      assert output.continue == true
      assert output.decision == nil
      assert output.reason == nil
      assert output.hook_specific_output == nil
    end

    test "allow_with_context/1 creates allow output with additional context" do
      output = UserPromptSubmit.Output.allow_with_context("Current time: 2024-03-15")

      assert output.continue == true
      assert output.decision == nil
      assert output.hook_specific_output.hook_event_name == "UserPromptSubmit"
      assert output.hook_specific_output.additional_context == "Current time: 2024-03-15"
    end

    test "block/1 creates block decision output" do
      output = UserPromptSubmit.Output.block("Prompt contains sensitive information")

      assert output.continue == true
      assert output.decision == :block
      assert output.reason == "Prompt contains sensitive information"
    end

    test "output can be encoded to JSON string" do
      output = UserPromptSubmit.Output.block("Invalid prompt")
      json = Jason.encode!(output)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == true
      assert decoded["decision"] == "block"
      assert decoded["reason"] == "Invalid prompt"
    end

    test "Jason.Encoder implementation converts snake_case to camelCase" do
      output = %UserPromptSubmit.Output{
        continue: false,
        stop_reason: "Security violation",
        suppress_output: true,
        hook_specific_output: %{
          hook_event_name: "UserPromptSubmit",
          additional_context: "Added context"
        }
      }

      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == false
      assert decoded["stopReason"] == "Security violation"
      assert decoded["suppressOutput"] == true
      assert decoded["hookSpecificOutput"]["hookEventName"] == "UserPromptSubmit"
      assert decoded["hookSpecificOutput"]["additionalContext"] == "Added context"
    end

    test "Jason.Encoder filters nil values" do
      output = UserPromptSubmit.Output.allow()
      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded == %{"continue" => true, "suppressOutput" => false}
      refute Map.has_key?(decoded, "decision")
      refute Map.has_key?(decoded, "reason")
      refute Map.has_key?(decoded, "hookSpecificOutput")
    end

    test "Jason.Encoder handles context without blocking" do
      output = UserPromptSubmit.Output.allow_with_context("Extra info")
      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == true
      assert decoded["hookSpecificOutput"]["additionalContext"] == "Extra info"
      refute Map.has_key?(decoded, "decision")
    end
  end
end
