defmodule Claude.Hooks.Events.PreToolUseTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.PreToolUse

  describe "Input" do
    test "new/1 creates struct from map" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "PreToolUse",
        "tool_name" => "Write",
        "tool_input" => %{
          "file_path" => "/test.ex",
          "content" => "defmodule Test do\nend"
        }
      }

      input = PreToolUse.Input.new(attrs)

      assert input.session_id == "test-123"
      assert input.transcript_path == "/path/to/transcript.jsonl"
      assert input.cwd == "/project"
      assert input.hook_event_name == "PreToolUse"
      assert input.tool_name == "Write"
      assert %Claude.Hooks.ToolInputs.Write{} = input.tool_input
      assert input.tool_input.file_path == "/test.ex"
      assert input.tool_input.content == "defmodule Test do\nend"
    end

    test "new/1 defaults hook_event_name if not provided" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "ls"}
      }

      input = PreToolUse.Input.new(attrs)
      assert input.hook_event_name == "PreToolUse"
    end

    test "new/1 handles unknown tools by keeping raw map" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "tool_name" => "UnknownTool",
        "tool_input" => %{"custom" => "data"}
      }

      input = PreToolUse.Input.new(attrs)
      assert input.tool_input == %{"custom" => "data"}
    end

    test "from_json/1 parses valid JSON" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "PreToolUse",
        "tool_name": "Edit",
        "tool_input": {
          "file_path": "/test.ex",
          "old_string": "old",
          "new_string": "new"
        }
      })

      {:ok, input} = PreToolUse.Input.from_json(json)

      assert input.session_id == "test-123"
      assert input.tool_name == "Edit"
      assert %Claude.Hooks.ToolInputs.Edit{} = input.tool_input
      assert input.tool_input.file_path == "/test.ex"
      assert input.tool_input.old_string == "old"
      assert input.tool_input.new_string == "new"
    end

    test "from_json/1 handles invalid JSON" do
      assert {:error, _} = PreToolUse.Input.from_json("invalid json")
    end

    test "Jason.Encoder implementation encodes Input struct" do
      input = %PreToolUse.Input{
        session_id: "test-123",
        transcript_path: "/path/to/transcript.jsonl",
        cwd: "/project",
        hook_event_name: "PreToolUse",
        tool_name: "Write",
        tool_input: %Claude.Hooks.ToolInputs.Write{
          file_path: "/test.ex",
          content: "content"
        }
      }

      json = Jason.encode!(input)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-123"
      assert decoded["tool_name"] == "Write"
      assert decoded["tool_input"]["file_path"] == "/test.ex"
      assert decoded["tool_input"]["content"] == "content"
    end
  end

  describe "Output" do
    test "allow/0 creates allow decision output" do
      output = PreToolUse.Output.allow()

      assert output.continue == true
      assert output.hook_specific_output.permission_decision == :allow
      assert output.hook_specific_output.permission_decision_reason == nil
      assert output.hook_specific_output.hook_event_name == "PreToolUse"
    end

    test "allow/1 creates allow decision with reason" do
      output = PreToolUse.Output.allow("Auto-approved for read operations")

      assert output.hook_specific_output.permission_decision == :allow
      assert output.hook_specific_output.permission_decision_reason == "Auto-approved for read operations"
    end

    test "deny/1 creates deny decision output" do
      output = PreToolUse.Output.deny("Dangerous operation detected")

      assert output.continue == true
      assert output.hook_specific_output.permission_decision == :deny
      assert output.hook_specific_output.permission_decision_reason == "Dangerous operation detected"
    end

    test "ask/0 creates ask decision output" do
      output = PreToolUse.Output.ask()

      assert output.continue == true
      assert output.hook_specific_output.permission_decision == :ask
      assert output.hook_specific_output.permission_decision_reason == nil
    end

    test "ask/1 creates ask decision with reason" do
      output = PreToolUse.Output.ask("Manual review required")

      assert output.hook_specific_output.permission_decision == :ask
      assert output.hook_specific_output.permission_decision_reason == "Manual review required"
    end

    test "output can be encoded to JSON string" do
      output = PreToolUse.Output.allow("Test reason")
      json = Jason.encode!(output)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == true
      assert decoded["hookSpecificOutput"]["permissionDecision"] == "allow"
      assert decoded["hookSpecificOutput"]["permissionDecisionReason"] == "Test reason"
      assert decoded["hookSpecificOutput"]["hookEventName"] == "PreToolUse"
    end

    test "Jason.Encoder implementation converts snake_case to camelCase" do
      output = %PreToolUse.Output{
        continue: false,
        stop_reason: "Test stop",
        suppress_output: true,
        hook_specific_output: %{
          hook_event_name: "PreToolUse",
          permission_decision: :deny,
          permission_decision_reason: "Not allowed"
        }
      }

      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == false
      assert decoded["stopReason"] == "Test stop"
      assert decoded["suppressOutput"] == true
      assert decoded["hookSpecificOutput"]["hookEventName"] == "PreToolUse"
      assert decoded["hookSpecificOutput"]["permissionDecision"] == "deny"
      assert decoded["hookSpecificOutput"]["permissionDecisionReason"] == "Not allowed"
    end

    test "Jason.Encoder filters nil values" do
      output = PreToolUse.Output.allow()
      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      refute Map.has_key?(decoded, "stopReason")
      refute Map.has_key?(decoded, "decision")
      refute Map.has_key?(decoded, "reason")
      refute Map.has_key?(decoded["hookSpecificOutput"], "permissionDecisionReason")
    end

    test "Jason.Encoder handles deprecated fields" do
      output = %PreToolUse.Output{
        continue: true,
        decision: :approve,
        reason: "Legacy reason"
      }

      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded["decision"] == "approve"
      assert decoded["reason"] == "Legacy reason"
    end
  end
end