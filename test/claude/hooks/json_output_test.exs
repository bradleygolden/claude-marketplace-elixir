defmodule Claude.Hooks.JsonOutputTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.JsonOutput

  describe "success/1" do
    test "creates success output with default options" do
      output = JsonOutput.success()
      assert output.continue == true
      assert output.suppressOutput == false
      assert output.stopReason == nil
    end

    test "creates success output with suppress_output option" do
      output = JsonOutput.success(suppress_output: true)
      assert output.continue == true
      assert output.suppressOutput == true
    end
  end

  describe "stop/2" do
    test "creates stop output with reason" do
      output = JsonOutput.stop("Operation cancelled by user")
      assert output.continue == false
      assert output.stopReason == "Operation cancelled by user"
      assert output.suppressOutput == false
    end
  end

  describe "block_post_tool/2" do
    test "creates blocking decision for PostToolUse" do
      output = JsonOutput.block_post_tool("Compilation failed")
      assert output.decision == "block"
      assert output.reason == "Compilation failed"
      assert output.suppressOutput == false
    end
  end

  describe "deny_pre_tool/2" do
    test "creates deny decision for PreToolUse" do
      output = JsonOutput.deny_pre_tool("Permission denied")
      assert output.hookSpecificOutput.hookEventName == "PreToolUse"
      assert output.hookSpecificOutput.permissionDecision == "deny"
      assert output.hookSpecificOutput.permissionDecisionReason == "Permission denied"
    end
  end

  describe "allow_pre_tool/2" do
    test "creates allow decision for PreToolUse without reason" do
      output = JsonOutput.allow_pre_tool()
      assert output.hookSpecificOutput.hookEventName == "PreToolUse"
      assert output.hookSpecificOutput.permissionDecision == "allow"
      refute Map.has_key?(output.hookSpecificOutput, :permissionDecisionReason)
    end

    test "creates allow decision for PreToolUse with reason" do
      output = JsonOutput.allow_pre_tool("Auto-approved")
      assert output.hookSpecificOutput.hookEventName == "PreToolUse"
      assert output.hookSpecificOutput.permissionDecision == "allow"
      assert output.hookSpecificOutput.permissionDecisionReason == "Auto-approved"
    end
  end

  describe "ask_pre_tool/2" do
    test "creates ask decision for PreToolUse" do
      output = JsonOutput.ask_pre_tool("Please confirm this action")
      assert output.hookSpecificOutput.hookEventName == "PreToolUse"
      assert output.hookSpecificOutput.permissionDecision == "ask"
      assert output.hookSpecificOutput.permissionDecisionReason == "Please confirm this action"
    end
  end

  describe "block_prompt/2" do
    test "creates block decision for UserPromptSubmit" do
      output = JsonOutput.block_prompt("Invalid prompt")
      assert output.decision == "block"
      assert output.reason == "Invalid prompt"
    end
  end

  describe "add_context/2" do
    test "creates output with additional context" do
      output = JsonOutput.add_context("Current time: 2024-01-01")
      assert output.hookSpecificOutput.hookEventName == "UserPromptSubmit"
      assert output.hookSpecificOutput.additionalContext == "Current time: 2024-01-01"
    end
  end

  describe "block_stop/2" do
    test "creates block decision for Stop/SubagentStop" do
      output = JsonOutput.block_stop("Must complete task first")
      assert output.decision == "block"
      assert output.reason == "Must complete task first"
    end
  end

  describe "to_json/1" do
    test "converts output to JSON string without nil values" do
      output = JsonOutput.success(suppress_output: true)
      json = JsonOutput.to_json(output)

      decoded = Jason.decode!(json)
      assert decoded["continue"] == true
      assert decoded["suppressOutput"] == true
      refute Map.has_key?(decoded, "stopReason")
      refute Map.has_key?(decoded, "decision")
      refute Map.has_key?(decoded, "reason")
    end

    test "properly encodes hook specific output" do
      output = JsonOutput.deny_pre_tool("Test reason")
      json = JsonOutput.to_json(output)

      decoded = Jason.decode!(json)
      assert decoded["hookSpecificOutput"]["hookEventName"] == "PreToolUse"
      assert decoded["hookSpecificOutput"]["permissionDecision"] == "deny"
      assert decoded["hookSpecificOutput"]["permissionDecisionReason"] == "Test reason"
    end
  end
end
