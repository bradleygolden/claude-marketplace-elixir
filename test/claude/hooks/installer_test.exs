defmodule Claude.Hooks.InstallerTest do
  use ExUnit.Case, async: true

  alias Claude.Hooks.Installer

  describe "install_hooks/1" do
    test "installs all hooks into empty settings" do
      settings = %{}

      result = Installer.install_hooks(settings)

      assert %{"hooks" => hooks} = result
      assert %{"PostToolUse" => post_tool_use} = hooks
      assert %{"PreToolUse" => pre_tool_use} = hooks

      # Check PostToolUse hooks
      assert [%{"matcher" => ".*", "hooks" => post_hooks}] = post_tool_use
      assert length(post_hooks) == 2

      assert Enum.any?(post_hooks, fn hook ->
               hook["command"] =~ "post_tool_use.elixir_formatter" &&
                 hook["type"] == "command"
             end)

      assert Enum.any?(post_hooks, fn hook ->
               hook["command"] =~ "post_tool_use.compilation_checker" &&
                 hook["type"] == "command"
             end)

      # Check PreToolUse hooks
      assert [%{"matcher" => "Bash", "hooks" => pre_hooks}] = pre_tool_use
      assert length(pre_hooks) == 1

      assert Enum.any?(pre_hooks, fn hook ->
               hook["command"] =~ "pre_tool_use.pre_commit_check" &&
                 hook["type"] == "command"
             end)
    end

    test "preserves existing non-Claude hooks" do
      settings = %{
        "hooks" => %{
          "PostToolUse" => [
            %{
              "matcher" => ".*",
              "hooks" => [
                %{"command" => "echo 'custom hook'", "type" => "command"}
              ]
            }
          ]
        }
      }

      result = Installer.install_hooks(settings)

      post_tool_use = get_in(result, ["hooks", "PostToolUse"])
      assert [%{"matcher" => ".*", "hooks" => hooks}] = post_tool_use

      # Should have custom hook + 2 Claude hooks
      assert length(hooks) == 3

      assert Enum.any?(hooks, fn hook ->
               hook["command"] == "echo 'custom hook'"
             end)
    end

    test "replaces existing Claude hooks" do
      # Use an actual Claude hook command to test replacement
      old_command =
        "cd $CLAUDE_PROJECT_DIR && mix claude hooks run post_tool_use.elixir_formatter \"$1\" \"$2\""

      settings = %{
        "hooks" => %{
          "PostToolUse" => [
            %{
              "matcher" => ".*",
              "hooks" => [
                # This is an old version of the formatter hook that should be replaced
                %{"command" => old_command, "type" => "command"},
                %{"command" => "echo 'custom'", "type" => "command"}
              ]
            }
          ]
        }
      }

      result = Installer.install_hooks(settings)

      post_tool_use = get_in(result, ["hooks", "PostToolUse"])
      assert [%{"matcher" => ".*", "hooks" => hooks}] = post_tool_use

      # Should have exactly 3 hooks: custom + 2 Claude hooks (no duplicates)
      assert length(hooks) == 3

      # Count formatter hooks - should be exactly 1
      formatter_hooks =
        Enum.filter(hooks, fn hook ->
          hook["command"] =~ "post_tool_use.elixir_formatter"
        end)

      assert length(formatter_hooks) == 1

      # Should have new Claude hooks
      assert Enum.any?(hooks, fn hook ->
               hook["command"] =~ "post_tool_use.elixir_formatter"
             end)

      assert Enum.any?(hooks, fn hook ->
               hook["command"] =~ "post_tool_use.compilation_checker"
             end)

      # Should still have custom hook
      assert Enum.any?(hooks, fn hook ->
               hook["command"] == "echo 'custom'"
             end)
    end

    test "handles multiple matchers correctly" do
      settings = %{
        "hooks" => %{
          "PostToolUse" => [
            %{
              "matcher" => "*.ex",
              "hooks" => [
                %{"command" => "echo 'elixir file'", "type" => "command"}
              ]
            }
          ]
        }
      }

      result = Installer.install_hooks(settings)

      post_tool_use = get_in(result, ["hooks", "PostToolUse"])

      # Should have both matchers
      assert length(post_tool_use) == 2

      # Find the .* matcher
      assert Enum.any?(post_tool_use, fn matcher_obj ->
               matcher_obj["matcher"] == ".*" &&
                 length(matcher_obj["hooks"]) == 2
             end)

      # Find the *.ex matcher
      assert Enum.any?(post_tool_use, fn matcher_obj ->
               matcher_obj["matcher"] == "*.ex" &&
                 length(matcher_obj["hooks"]) == 1 &&
                 hd(matcher_obj["hooks"])["command"] == "echo 'elixir file'"
             end)
    end
  end

  describe "remove_all_hooks/1" do
    test "removes all Claude hooks" do
      settings = %{
        "hooks" => %{
          "PostToolUse" => [
            %{
              "matcher" => ".*",
              "hooks" => [
                %{
                  "command" =>
                    "cd $CLAUDE_PROJECT_DIR && mix claude hooks run post_tool_use.elixir_formatter \"$1\" \"$2\"",
                  "type" => "command"
                },
                %{"command" => "echo 'custom'", "type" => "command"}
              ]
            }
          ]
        }
      }

      result = Installer.remove_all_hooks(settings)

      # Should still have hooks key
      assert %{"hooks" => _hooks} = result

      # Should only have custom hook
      post_tool_use = get_in(result, ["hooks", "PostToolUse"])
      assert [%{"matcher" => ".*", "hooks" => [hook]}] = post_tool_use
      assert hook["command"] == "echo 'custom'"
    end

    test "removes hooks key when no hooks remain" do
      settings = %{
        "hooks" => %{
          "PostToolUse" => [
            %{
              "matcher" => ".*",
              "hooks" => [
                %{
                  "command" =>
                    "cd $CLAUDE_PROJECT_DIR && mix claude hooks run post_tool_use.elixir_formatter \"$1\" \"$2\"",
                  "type" => "command"
                }
              ]
            }
          ]
        }
      }

      result = Installer.remove_all_hooks(settings)

      # Should remove hooks key entirely
      refute Map.has_key?(result, "hooks")
    end

    test "handles empty settings" do
      assert %{} = Installer.remove_all_hooks(%{})
    end

    test "preserves other settings keys" do
      settings = %{
        "other_setting" => "value",
        "hooks" => %{}
      }

      result = Installer.remove_all_hooks(settings)

      assert %{"other_setting" => "value"} = result
      refute Map.has_key?(result, "hooks")
    end
  end

  describe "format_hooks_list/0" do
    test "formats hooks with bullet points" do
      formatted = Installer.format_hooks_list()

      lines = String.split(formatted, "\n")
      assert length(lines) == 3

      assert Enum.all?(lines, fn line ->
               String.starts_with?(line, "  • ")
             end)

      assert Enum.any?(lines, fn line ->
               line =~ "formatting"
             end)

      assert Enum.any?(lines, fn line ->
               line =~ "compilation"
             end)

      assert Enum.any?(lines, fn line ->
               line =~ "commit"
             end)
    end
  end
end
