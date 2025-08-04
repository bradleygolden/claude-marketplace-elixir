defmodule Claude.Test.FixturesTest do
  use ExUnit.Case, async: true
  alias Claude.Test.Fixtures
  alias Claude.Hooks.Events
  alias Claude.Hooks.ToolInputs

  describe "hook input fixtures" do
    test "pre_tool_use_input creates valid struct with defaults" do
      input = Fixtures.pre_tool_use_input()

      assert %Events.PreToolUse.Input{} = input
      assert input.session_id == "test-session-123"
      assert input.hook_event_name == "PreToolUse"
      assert input.tool_name == "Edit"
      assert %ToolInputs.Edit{} = input.tool_input
    end

    test "pre_tool_use_input accepts overrides" do
      custom_tool = Fixtures.tool_input(:write, file_path: "/custom.ex")

      input =
        Fixtures.pre_tool_use_input(
          session_id: "custom-session",
          tool_name: "Write",
          tool_input: custom_tool
        )

      assert input.session_id == "custom-session"
      assert input.tool_name == "Write"
      assert %ToolInputs.Write{} = input.tool_input
      assert input.tool_input.file_path == "/custom.ex"
    end

    test "post_tool_use_input includes tool_response" do
      input =
        Fixtures.post_tool_use_input(
          tool_response: %{"success" => false, "error" => "compilation failed"}
        )

      assert input.tool_response == %{"success" => false, "error" => "compilation failed"}
    end

    test "fixtures can be encoded to JSON" do
      input = Fixtures.pre_tool_use_input()
      json = Jason.encode!(input)

      assert is_binary(json)
      decoded = Jason.decode!(json)

      assert decoded["session_id"] == "test-session-123"
      assert decoded["tool_name"] == "Edit"
      assert decoded["tool_input"]["file_path"] == "/test/file.ex"
    end
  end

  describe "tool input fixtures" do
    test "tool_input(:edit) creates Edit struct" do
      input = Fixtures.tool_input(:edit)

      assert %ToolInputs.Edit{} = input
      assert input.file_path == "/test/file.ex"
      assert input.old_string == "old content"
      assert input.new_string == "new content"
      assert input.replace_all == false
    end

    test "tool_input(:write) creates Write struct" do
      input = Fixtures.tool_input(:write, content: "custom content")

      assert %ToolInputs.Write{} = input
      assert input.content == "custom content"
    end

    test "tool_input(:bash) creates Bash struct" do
      input =
        Fixtures.tool_input(:bash,
          command: "mix test",
          description: "Run tests"
        )

      assert %ToolInputs.Bash{} = input
      assert input.command == "mix test"
      assert input.description == "Run tests"
    end

    test "tool inputs can be nested in hook inputs" do
      bash_input = Fixtures.tool_input(:bash, command: "ls -la")

      hook_input =
        Fixtures.pre_tool_use_input(
          tool_name: "Bash",
          tool_input: bash_input
        )

      assert hook_input.tool_name == "Bash"
      assert hook_input.tool_input.command == "ls -la"
    end
  end

  describe "other hook input types" do
    test "notification_input creates valid struct" do
      input = Fixtures.notification_input(message: "Custom notification")

      assert %Events.Notification.Input{} = input
      assert input.message == "Custom notification"
    end

    test "user_prompt_submit_input creates valid struct" do
      input = Fixtures.user_prompt_submit_input(prompt: "Help me write tests")

      assert %Events.UserPromptSubmit.Input{} = input
      assert input.prompt == "Help me write tests"
    end

    test "stop_input creates valid struct" do
      input = Fixtures.stop_input(stop_hook_active: true)

      assert %Events.Stop.Input{} = input
      assert input.stop_hook_active == true
    end

    test "pre_compact_input creates valid struct" do
      input =
        Fixtures.pre_compact_input(
          trigger: :auto,
          custom_instructions: "Keep test files"
        )

      assert %Events.PreCompact.Input{} = input
      assert input.trigger == :auto
      assert input.custom_instructions == "Keep test files"
    end
  end
end
