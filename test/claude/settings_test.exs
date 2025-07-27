defmodule Claude.SettingsTest do
  use ExUnit.Case, async: true
  alias Claude.Settings
  alias Claude.Hooks.Hook

  describe "new/1" do
    test "handles hooks with matcher structure and converts to Hook structs" do
      attrs = %{
        "hooks" => %{
          "PreToolUse" => [
            %{
              "matcher" => "*.ex",
              "hooks" => [
                %{"type" => "shell", "command" => "echo 'Pre-tool use for Elixir files'"}
              ]
            }
          ],
          "PostToolUse" => [
            %{
              "matcher" => "*.ex",
              "hooks" => [
                %{"type" => "shell", "command" => "mix format"},
                %{"type" => "shell", "command" => "mix compile --warnings-as-errors"}
              ]
            },
            %{
              "matcher" => "*.exs",
              "hooks" => [
                %{"type" => "shell", "command" => "mix format"}
              ]
            }
          ]
        }
      }

      settings = Settings.new(attrs)

      # Check PreToolUse hooks
      assert [pre_tool_use_matcher] = settings.hooks["PreToolUse"]
      assert pre_tool_use_matcher["matcher"] == "*.ex"
      assert [hook] = pre_tool_use_matcher["hooks"]

      assert %Hook{type: "shell", command: "echo 'Pre-tool use for Elixir files'"} = hook

      # Check PostToolUse hooks  
      assert length(settings.hooks["PostToolUse"]) == 2

      [ex_matcher, exs_matcher] = settings.hooks["PostToolUse"]

      assert ex_matcher["matcher"] == "*.ex"
      assert [format_hook, compile_hook] = ex_matcher["hooks"]
      assert %Hook{type: "shell", command: "mix format"} = format_hook

      assert %Hook{type: "shell", command: "mix compile --warnings-as-errors"} = compile_hook

      assert exs_matcher["matcher"] == "*.exs"
      assert [exs_format_hook] = exs_matcher["hooks"]
      assert %Hook{type: "shell", command: "mix format"} = exs_format_hook
    end

    test "handles empty map" do
      settings = Settings.new(%{})

      assert settings.hooks == nil
    end

    test "handles simple hook format from settings docs" do
      attrs = %{
        "hooks" => %{
          "PreToolUse" => %{
            "Bash" => "echo 'Running command...'",
            "Write" => "echo 'Writing file...'"
          },
          "PostToolUse" => %{
            "Edit" => "mix format"
          }
        }
      }

      settings = Settings.new(attrs)

      # Check PreToolUse hooks are converted to complex format
      pre_hooks = settings.hooks["PreToolUse"]
      assert length(pre_hooks) == 2

      bash_matcher = Enum.find(pre_hooks, fn m -> m["matcher"] == "Bash" end)
      assert bash_matcher
      assert [bash_hook] = bash_matcher["hooks"]
      assert %Hook{type: "command", command: "echo 'Running command...'"} = bash_hook

      write_matcher = Enum.find(pre_hooks, fn m -> m["matcher"] == "Write" end)
      assert write_matcher
      assert [write_hook] = write_matcher["hooks"]
      assert %Hook{type: "command", command: "echo 'Writing file...'"} = write_hook

      # Check PostToolUse hooks
      post_hooks = settings.hooks["PostToolUse"]
      assert length(post_hooks) == 1

      [edit_matcher] = post_hooks
      assert edit_matcher["matcher"] == "Edit"
      assert [edit_hook] = edit_matcher["hooks"]
      assert %Hook{type: "command", command: "mix format"} = edit_hook
    end

    test "ignores other fields and focuses on hooks" do
      attrs = %{
        "hooks" => %{
          "PreToolUse" => [
            %{
              "matcher" => "*.ex",
              "hooks" => [%{"type" => "shell", "command" => "echo 'test'"}]
            }
          ]
        },
        "apiKeyHelper" => "/bin/key.sh",
        "model" => "claude-3-5-sonnet",
        "permissions" => %{"allow" => ["Read"]}
      }

      settings = Settings.new(attrs)

      assert [matcher] = settings.hooks["PreToolUse"]
      assert matcher["matcher"] == "*.ex"
      assert [hook] = matcher["hooks"]
      assert %Hook{type: "shell", command: "echo 'test'"} = hook
      assert Map.keys(Map.from_struct(settings)) == [:hooks]
    end
  end

  describe "from_json/1" do
    test "parses valid JSON with hooks structure" do
      json = """
      {
        "hooks": {
          "PostToolUse": [
            {
              "matcher": "*.ex",
              "hooks": [
                {"type": "shell", "command": "mix format"}
              ]
            }
          ]
        }
      }
      """

      assert {:ok, settings} = Settings.from_json(json)

      assert [matcher] = settings.hooks["PostToolUse"]
      assert matcher["matcher"] == "*.ex"
      assert [hook] = matcher["hooks"]
      assert %Hook{type: "shell", command: "mix format"} = hook
    end

    test "returns error for invalid JSON" do
      assert {:error, _} = Settings.from_json("invalid json")
    end
  end

  describe "Jason.Encoder" do
    test "encodes struct to JSON maintaining structure" do
      settings = %Settings{
        hooks: %{
          "PostToolUse" => [
            %{
              "matcher" => "*.ex",
              "hooks" => [
                %{"type" => "shell", "command" => "mix compile --warnings-as-errors"}
              ]
            }
          ]
        }
      }

      json = Jason.encode!(settings)
      decoded = Jason.decode!(json)

      assert decoded["hooks"]["PostToolUse"] == [
               %{
                 "matcher" => "*.ex",
                 "hooks" => [
                   %{"type" => "shell", "command" => "mix compile --warnings-as-errors"}
                 ]
               }
             ]
    end

    test "encodes Hook structs properly" do
      settings = %Settings{
        hooks: %{
          "PostToolUse" => [
            %{
              "matcher" => "*.ex",
              "hooks" => [
                Hook.new(%{type: "shell", command: "mix format"}),
                Hook.new(%{type: "shell", command: "mix compile"})
              ]
            }
          ]
        }
      }

      json = Jason.encode!(settings)
      decoded = Jason.decode!(json)

      assert decoded["hooks"]["PostToolUse"] == [
               %{
                 "matcher" => "*.ex",
                 "hooks" => [
                   %{"type" => "shell", "command" => "mix format"},
                   %{"type" => "shell", "command" => "mix compile"}
                 ]
               }
             ]
    end

    test "encodes empty struct" do
      settings = %Settings{}

      json = Jason.encode!(settings)
      decoded = Jason.decode!(json)

      assert decoded == %{}
    end

    test "encodes simple format hooks to complex format" do
      # Create settings from simple format
      attrs = %{
        "hooks" => %{
          "PreToolUse" => %{
            "Bash" => "echo 'test'"
          }
        }
      }

      settings = Settings.new(attrs)

      # Encode and decode
      json = Jason.encode!(settings)
      decoded = Jason.decode!(json)

      # Should be encoded as complex format
      assert decoded["hooks"]["PreToolUse"] == [
               %{
                 "matcher" => "Bash",
                 "hooks" => [
                   %{"type" => "command", "command" => "echo 'test'"}
                 ]
               }
             ]
    end
  end
end
