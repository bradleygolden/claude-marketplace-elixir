defmodule Claude.HooksTest do
  use Claude.Test.ClaudeCodeCase

  alias Claude.Hooks

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
    @tag :skip
    test "returns all registered hooks" do
      # This test relied on all_hooks() which has been removed
    end
  end

  # Note: find_hook_by_identifier tests removed - function no longer needed with script-based hooks

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
    @tag :skip
    test "all hooks implement the required callbacks" do
      # This test relied on all_hooks() which has been removed
    end

    test "hooks ignore user config in command generation" do
      defmodule TestConfigurableHook do
        use Claude.Hooks.Hook.Behaviour,
          event: :post_tool_use,
          matcher: :write,
          description: "Test hook with user configuration"
      end

      # No config
      config1 = TestConfigurableHook.config()
      assert config1.command =~ "Hook command configured by installer"

      # With config
      user_config = %{
        "patterns" => [
          %{"source" => "*.ex", "target" => "*.exs"}
        ]
      }

      config2 = TestConfigurableHook.config(user_config)
      assert config2.command =~ "Hook command configured by installer"

      # Commands should be the same since config is ignored
      assert config1.command == config2.command
    end

    test "hooks with run/2 can accept user config" do
      defmodule TestHookWithConfig do
        use Claude.Hooks.Hook.Behaviour,
          event: :post_tool_use,
          matcher: :write,
          description: "Test hook that accepts config"

        @impl Claude.Hooks.Hook.Behaviour
        def run(_json_input, user_config) do
          patterns = Map.get(user_config, :patterns, [])
          # Store the config for testing
          send(self(), {:hook_executed, patterns})
          :ok
        end
      end

      test_config = %{
        patterns: [
          {"lib/**/*.ex", "test/**/*_test.exs"}
        ],
        custom_option: "test_value"
      }

      json_input =
        Jason.encode!(%{
          "hook_event_name" => "PostToolUse",
          "tool_name" => "Write",
          "tool_input" => %{
            "file_path" => "lib/example.ex"
          }
        })

      # Run hook with config
      TestHookWithConfig.run(json_input, test_config)

      # Should receive the patterns from config
      assert_receive {:hook_executed, patterns}
      assert patterns == [{"lib/**/*.ex", "test/**/*_test.exs"}]
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
