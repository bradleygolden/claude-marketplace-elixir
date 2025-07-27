defmodule Claude.Hooks.Events.PostToolUseTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events.PostToolUse

  describe "Input" do
    test "new/1 creates struct from map with tool response" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "hook_event_name" => "PostToolUse",
        "tool_name" => "Write",
        "tool_input" => %{
          "file_path" => "/test.ex",
          "content" => "defmodule Test do\nend"
        },
        "tool_response" => %{
          "filePath" => "/test.ex",
          "success" => true
        }
      }

      input = PostToolUse.Input.new(attrs)

      assert input.session_id == "test-123"
      assert input.transcript_path == "/path/to/transcript.jsonl"
      assert input.cwd == "/project"
      assert input.hook_event_name == "PostToolUse"
      assert input.tool_name == "Write"
      assert %Claude.Hooks.ToolInputs.Write{} = input.tool_input
      assert input.tool_input.file_path == "/test.ex"
      assert input.tool_response == %{"filePath" => "/test.ex", "success" => true}
    end

    test "new/1 defaults hook_event_name if not provided" do
      attrs = %{
        "session_id" => "test-123",
        "transcript_path" => "/path/to/transcript.jsonl",
        "cwd" => "/project",
        "tool_name" => "Bash",
        "tool_input" => %{"command" => "ls"},
        "tool_response" => %{"exitCode" => 0}
      }

      input = PostToolUse.Input.new(attrs)
      assert input.hook_event_name == "PostToolUse"
    end

    test "from_json/1 parses valid JSON" do
      json = ~s({
        "session_id": "test-123",
        "transcript_path": "/path/to/transcript.jsonl",
        "cwd": "/project",
        "hook_event_name": "PostToolUse",
        "tool_name": "Edit",
        "tool_input": {
          "file_path": "/test.ex",
          "old_string": "old",
          "new_string": "new"
        },
        "tool_response": {
          "success": true,
          "linesModified": 5
        }
      })

      {:ok, input} = PostToolUse.Input.from_json(json)

      assert input.session_id == "test-123"
      assert input.tool_name == "Edit"
      assert %Claude.Hooks.ToolInputs.Edit{} = input.tool_input
      assert input.tool_response["success"] == true
      assert input.tool_response["linesModified"] == 5
    end

    test "from_json/1 handles invalid JSON" do
      assert {:error, _} = PostToolUse.Input.from_json("invalid json")
    end

    test "Jason.Encoder implementation encodes Input struct" do
      input = %PostToolUse.Input{
        session_id: "test-123",
        transcript_path: "/path/to/transcript.jsonl",
        cwd: "/project",
        hook_event_name: "PostToolUse",
        tool_name: "Write",
        tool_input: %Claude.Hooks.ToolInputs.Write{
          file_path: "/test.ex",
          content: "content"
        },
        tool_response: %{"success" => true}
      }

      json = Jason.encode!(input)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-123"
      assert decoded["tool_name"] == "Write"
      assert decoded["tool_response"]["success"] == true
    end
  end

  describe "Output" do
    test "success/0 creates success output" do
      output = PostToolUse.Output.success()

      assert output.continue == true
      assert output.decision == nil
      assert output.reason == nil
    end

    test "block/1 creates block decision output" do
      output = PostToolUse.Output.block("Tests failed after edit")

      assert output.continue == true
      assert output.decision == :block
      assert output.reason == "Tests failed after edit"
    end

    test "output can be encoded to JSON string" do
      output = PostToolUse.Output.block("Compilation error")
      json = Jason.encode!(output)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == true
      assert decoded["decision"] == "block"
      assert decoded["reason"] == "Compilation error"
    end

    test "Jason.Encoder implementation converts snake_case to camelCase" do
      output = %PostToolUse.Output{
        continue: false,
        stop_reason: "Critical error",
        suppress_output: true,
        decision: :block,
        reason: "Failed"
      }

      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded["continue"] == false
      assert decoded["stopReason"] == "Critical error"
      assert decoded["suppressOutput"] == true
      assert decoded["decision"] == "block"
      assert decoded["reason"] == "Failed"
    end

    test "Jason.Encoder filters nil values" do
      output = PostToolUse.Output.success()
      json = Jason.encode!(output)
      decoded = Jason.decode!(json)

      assert decoded == %{"continue" => true, "suppressOutput" => false}
      refute Map.has_key?(decoded, "stopReason")
      refute Map.has_key?(decoded, "decision")
      refute Map.has_key?(decoded, "reason")
    end
  end
end
