defmodule Claude.Hooks.InstallerTest do
  use Claude.Test.ClaudeCodeCase, async: false

  alias Claude.Hooks.Installer

  describe "install_hooks/1" do
    test "installs all hooks into empty settings" do
      settings = %{}

      result = Installer.install_hooks(settings)

      assert %{"hooks" => hooks} = result
      assert %{"PostToolUse" => post_tool_use} = hooks
      assert %{"PreToolUse" => pre_tool_use} = hooks

      assert [%{"matcher" => "Write|Edit|MultiEdit", "hooks" => post_hooks}] = post_tool_use
      assert length(post_hooks) == 2

      assert Enum.any?(post_hooks, fn hook ->
               hook["command"] =~ "post_tool_use.elixir_formatter" &&
                 hook["type"] == "command"
             end)

      assert Enum.any?(post_hooks, fn hook ->
               hook["command"] =~ "post_tool_use.compilation_checker" &&
                 hook["type"] == "command"
             end)

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
      assert length(post_tool_use) == 2

      custom_matcher = Enum.find(post_tool_use, fn m -> m["matcher"] == ".*" end)
      assert custom_matcher
      assert length(custom_matcher["hooks"]) == 1
      first_hook = hd(custom_matcher["hooks"])

      command =
        case first_hook do
          %Claude.Hooks.Hook{command: cmd} -> cmd
          %{"command" => cmd} -> cmd
        end

      assert command == "echo 'custom hook'"

      builtin_matcher =
        Enum.find(post_tool_use, fn m -> m["matcher"] == "Write|Edit|MultiEdit" end)

      assert builtin_matcher
      assert length(builtin_matcher["hooks"]) == 2
    end

    test "replaces existing Claude hooks" do
      old_command =
        "cd $CLAUDE_PROJECT_DIR && mix claude hooks run post_tool_use.elixir_formatter \"$1\" \"$2\""

      settings = %{
        "hooks" => %{
          "PostToolUse" => [
            %{
              "matcher" => ".*",
              "hooks" => [
                %{"command" => old_command, "type" => "command"},
                %{"command" => "echo 'custom'", "type" => "command"}
              ]
            }
          ]
        }
      }

      result = Installer.install_hooks(settings)

      post_tool_use = get_in(result, ["hooks", "PostToolUse"])
      assert length(post_tool_use) == 2

      custom_matcher = Enum.find(post_tool_use, fn m -> m["matcher"] == ".*" end)
      assert custom_matcher
      assert length(custom_matcher["hooks"]) == 1
      first_hook = hd(custom_matcher["hooks"])

      command =
        case first_hook do
          %Claude.Hooks.Hook{command: cmd} -> cmd
          %{"command" => cmd} -> cmd
        end

      assert command == "echo 'custom'"

      builtin_matcher =
        Enum.find(post_tool_use, fn m -> m["matcher"] == "Write|Edit|MultiEdit" end)

      assert builtin_matcher
      assert length(builtin_matcher["hooks"]) == 2

      builtin_commands = Enum.map(builtin_matcher["hooks"], & &1["command"])
      assert Enum.any?(builtin_commands, &(&1 =~ "post_tool_use.elixir_formatter"))
      assert Enum.any?(builtin_commands, &(&1 =~ "post_tool_use.compilation_checker"))
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

      assert length(post_tool_use) == 2

      assert Enum.any?(post_tool_use, fn matcher_obj ->
               matcher_obj["matcher"] == "Write|Edit|MultiEdit" &&
                 length(matcher_obj["hooks"]) == 2
             end)

      assert Enum.any?(post_tool_use, fn matcher_obj ->
               matcher_obj["matcher"] == "*.ex" &&
                 length(matcher_obj["hooks"]) == 1 &&
                 case hd(matcher_obj["hooks"]) do
                   %Claude.Hooks.Hook{command: cmd} -> cmd
                   %{"command" => cmd} -> cmd
                 end == "echo 'elixir file'"
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

      assert %{"hooks" => _hooks} = result

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

  describe "custom hooks integration" do
    setup do
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_installer_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)

      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          TestHooks.CustomFormatter
        ]
      }
      """)

      on_exit(fn -> File.rm_rf!(test_dir) end)

      {:ok, test_dir: test_dir}
    end

    test "installs custom hooks from .claude.exs", %{test_dir: test_dir} do
      stub(Claude.Core.Project, :root, fn -> test_dir end)

      settings = %{}
      result = Installer.install_hooks(settings)

      assert %{"hooks" => _hooks} = result

      post_tool_use = get_in(result, ["hooks", "PostToolUse"])

      custom_hook_found =
        Enum.any?(post_tool_use || [], fn matcher_obj ->
          Enum.any?(matcher_obj["hooks"] || [], fn hook ->
            command = if is_map(hook), do: hook["command"], else: ""
            command =~ "test_hooks.custom_formatter"
          end)
        end)

      assert custom_hook_found, "Custom hook should be installed"
    end

    test "format_hooks_list shows custom hooks with [Custom] prefix", %{test_dir: test_dir} do
      stub(Claude.Core.Project, :root, fn -> test_dir end)

      formatted = Installer.format_hooks_list()

      assert formatted =~ "formatting"
      assert formatted =~ "[Custom] Custom formatter for project-specific patterns"
    end

    test "removes custom hooks correctly", %{test_dir: test_dir} do
      stub(Claude.Core.Project, :root, fn -> test_dir end)

      settings = %{}
      with_hooks = Installer.install_hooks(settings)

      result = Installer.remove_all_hooks(with_hooks)

      refute Map.has_key?(result, "hooks")
    end
  end
end
