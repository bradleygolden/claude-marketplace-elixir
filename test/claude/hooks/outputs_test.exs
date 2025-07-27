defmodule Claude.Hooks.OutputsTest do
  use ExUnit.Case, async: true
  alias Claude.Hooks.Events
  alias Claude.Hooks.Events.Common

  describe "PreToolUseOutput" do
    test "creates allow output" do
      output = Events.PreToolUse.Output.allow("Auto-approved for documentation")

      assert output.hook_specific_output.permission_decision == :allow

      assert output.hook_specific_output.permission_decision_reason ==
               "Auto-approved for documentation"
    end

    test "creates deny output" do
      output = Events.PreToolUse.Output.deny("Dangerous operation detected")

      assert output.hook_specific_output.permission_decision == :deny

      assert output.hook_specific_output.permission_decision_reason ==
               "Dangerous operation detected"
    end

    test "creates ask output" do
      output = Events.PreToolUse.Output.ask("User confirmation required")

      assert output.hook_specific_output.permission_decision == :ask

      assert output.hook_specific_output.permission_decision_reason ==
               "User confirmation required"
    end

    test "converts to JSON with permission decision" do
      output = Events.PreToolUse.Output.allow("Test reason")

      json = Jason.encode!(output)
      assert json =~ ~s("permissionDecision":"allow")
      assert json =~ ~s("permissionDecisionReason":"Test reason")
    end

    test "converts to JSON excluding nil fields" do
      output = %Events.PreToolUse.Output{
        continue: false,
        stop_reason: "Test stop"
      }

      json = Jason.encode!(output)
      refute json =~ "hookSpecificOutput"
      refute json =~ "decision"
      assert json =~ ~s("continue":false)
      assert json =~ ~s("stopReason":"Test stop")
    end
  end

  describe "PostToolUseOutput" do
    test "creates block output" do
      output = Events.PostToolUse.Output.block("Compilation error detected")

      assert output.decision == :block
      assert output.reason == "Compilation error detected"
    end

    test "creates allow output" do
      output = Events.PostToolUse.Output.allow()

      assert output.decision == nil
      assert output.reason == nil
      assert output.continue == true
    end

    test "converts to JSON" do
      output = Events.PostToolUse.Output.block("Test reason")

      json = Jason.encode!(output)
      assert json =~ ~s("decision":"block")
      assert json =~ ~s("reason":"Test reason")
    end
  end

  describe "UserPromptSubmitOutput" do
    test "creates block output" do
      output = Events.UserPromptSubmit.Output.block("Sensitive content detected")

      assert output.decision == :block
      assert output.reason == "Sensitive content detected"
    end

    test "creates add context output" do
      output = Events.UserPromptSubmit.Output.add_context("Current time: 2024-01-01")

      assert output.hook_specific_output.additional_context == "Current time: 2024-01-01"
      assert output.decision == nil
    end

    test "converts to JSON with context" do
      output = Events.UserPromptSubmit.Output.add_context("Test context")

      json = Jason.encode!(output)
      assert json =~ ~s("additionalContext":"Test context")
      assert json =~ ~s("hookEventName":"UserPromptSubmit")
    end
  end

  describe "StopOutput" do
    test "creates block output" do
      output = Events.Stop.Output.block("More tasks to complete")

      assert output.decision == :block
      assert output.reason == "More tasks to complete"
    end

    test "creates allow output" do
      output = Events.Stop.Output.allow()

      assert output.decision == nil
      assert output.continue == true
    end

    test "converts to JSON" do
      output = Events.Stop.Output.block("Continue processing")

      json = Jason.encode!(output)
      assert json =~ ~s("decision":"block")
      assert json =~ ~s("reason":"Continue processing")
    end
  end

  describe "SimpleOutput" do
    test "creates success output" do
      output = Common.SimpleOutput.success("Operation completed")

      assert output.exit_code == 0
      assert output.stdout == "Operation completed"
      assert output.stderr == nil
    end

    test "creates block output" do
      output = Common.SimpleOutput.block("Invalid operation")

      assert output.exit_code == 2
      assert output.stderr == "Invalid operation"
      assert output.stdout == nil
    end

    test "creates error output" do
      output = Common.SimpleOutput.error("Non-critical error", 3)

      assert output.exit_code == 3
      assert output.stderr == "Non-critical error"
    end

    test "error rejects exit codes 0 and 2" do
      assert_raise FunctionClauseError, fn ->
        Common.SimpleOutput.error("Test", 0)
      end

      assert_raise FunctionClauseError, fn ->
        Common.SimpleOutput.error("Test", 2)
      end
    end
  end
end
