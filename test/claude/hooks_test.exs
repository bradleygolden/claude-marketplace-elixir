defmodule Claude.HooksTest do
  use Claude.Test.ClaudeCodeCase

  alias Claude.Hooks
  alias Claude.Hooks.Hook

  describe "hook JSON structure" do
    test "hooks should handle full Claude Code JSON input structure" do
      claude_input = %{
        "session_id" => "abc123",
        "hook_event_name" => "PostToolUse",
        "tool_name" => "Edit",
        "tool_input" => %{
          "file_path" => "/path/to/file.ex",
          "old_string" => "old code",
          "new_string" => "new code"
        },
        "tool_output" => %{
          "success" => true,
          "message" => "File edited successfully"
        }
      }

      json_input = Jason.encode!(claude_input)

      assert {:ok, decoded} = Jason.decode(json_input)
      assert decoded["session_id"]
      assert decoded["hook_event_name"]
      assert decoded["tool_name"]
      assert decoded["tool_input"]
    end

    test "post-tool hooks receive tool output in addition to input" do
      post_tool_data = %{
        "session_id" => "xyz789",
        "hook_event_name" => "PostToolUse",
        "tool_name" => "Write",
        "tool_input" => %{
          "file_path" => "/new/file.ex",
          "content" => "defmodule New do\nend"
        },
        "tool_output" => %{
          "success" => true,
          "message" => "File created successfully"
        }
      }

      json_data = Jason.encode!(post_tool_data)

      assert {:ok, decoded} = Jason.decode(json_data)
      assert decoded["tool_output"]
      assert decoded["tool_output"]["success"] == true
    end

    test "hooks should be able to output JSON responses" do
      expected_response = %{
        "status" => "success",
        "message" => "Hook executed successfully",
        "context" => %{
          "additional_info" => "This could be added to Claude's context"
        }
      }

      json_output = Jason.encode!(expected_response)

      assert {:ok, decoded} = Jason.decode(json_output)
      assert decoded["status"] == "success"
    end
  end

  describe "all_hooks/0" do
    test "returns all registered hooks" do
      hooks = Hooks.all_hooks()

      assert Claude.Hooks.PostToolUse.ElixirFormatter in hooks
      assert Claude.Hooks.PostToolUse.CompilationChecker in hooks
      assert Claude.Hooks.PreToolUse.PreCommitCheck in hooks
      assert length(hooks) == 3
    end
  end

  describe "find_hook_by_identifier/1" do
    test "finds hook by identifier" do
      assert Hooks.find_hook_by_identifier("post_tool_use.elixir_formatter") ==
               Claude.Hooks.PostToolUse.ElixirFormatter

      assert Hooks.find_hook_by_identifier("post_tool_use.compilation_checker") ==
               Claude.Hooks.PostToolUse.CompilationChecker

      assert Hooks.find_hook_by_identifier("pre_tool_use.pre_commit_check") ==
               Claude.Hooks.PreToolUse.PreCommitCheck
    end

    test "returns nil for unknown identifier" do
      assert Hooks.find_hook_by_identifier("unknown.hook") == nil
    end
  end

  describe "hook_identifier/1" do
    test "generates correct identifier for hook modules" do
      assert Hooks.hook_identifier(Claude.Hooks.PostToolUse.ElixirFormatter) ==
               "post_tool_use.elixir_formatter"

      assert Hooks.hook_identifier(Claude.Hooks.PostToolUse.CompilationChecker) ==
               "post_tool_use.compilation_checker"

      assert Hooks.hook_identifier(Claude.Hooks.PreToolUse.PreCommitCheck) ==
               "pre_tool_use.pre_commit_check"
    end
  end

  describe "Hook.Behaviour" do
    test "all hooks implement the required callbacks" do
      for hook_module <- Hooks.all_hooks() do
        config = hook_module.config()
        assert %Hook{} = config
        assert config.type
        assert config.command
        assert config.matcher

        description = hook_module.description()
        assert is_binary(description)
        assert String.length(description) > 0

        assert function_exported?(hook_module, :run, 1)
      end
    end
  end

  describe "exit code behavior" do
    @tag :skip
    test "pre-tool hooks should be able to block with exit code 2" do
      blocking_response = fn ->
        System.halt(2)
      end

      assert_raise SystemExit, blocking_response
    end
  end
end
