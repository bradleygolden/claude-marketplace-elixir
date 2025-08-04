defmodule Mix.Tasks.Claude.Gen.HookTest do
  use ExUnit.Case

  import Igniter.Test
  import ExUnit.CaptureIO

  setup do
    Mix.Task.clear()
    :ok
  end

  describe "claude.gen.hook" do
    test "generates a post_tool_use hook module" do
      hook_name = "TestFormatter"

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          hook_name,
          "--event",
          "post_tool_use",
          "--matcher",
          "write,edit",
          "--description",
          "Test formatting hook",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/post_tool_use/test_formatter.ex")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.PostToolUse.TestFormatter"
        )
      )

      source =
        Rewrite.source!(igniter.rewrite, "lib/claude/hooks/post_tool_use/test_formatter.ex")

      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/defmodule Claude\.Hooks\.PostToolUse\.TestFormatter do/
      assert content =~ ~r/Test formatting hook/
      assert content =~ ~r/event: :post_tool_use/
      assert content =~ ~r/matcher: \[:write, :edit\]/
      assert content =~ ~r/@impl Claude\.Hook/
      assert content =~ ~r/def handle\(input\) do/
    end

    test "generates a pre_tool_use hook module" do
      hook_name = "BashValidator"

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          hook_name,
          "--event",
          "pre_tool_use",
          "--matcher",
          "bash",
          "--description",
          "Validate bash commands",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/pre_tool_use/bash_validator.ex")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.PreToolUse.BashValidator"
        )
      )

      source = Rewrite.source!(igniter.rewrite, "lib/claude/hooks/pre_tool_use/bash_validator.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/defmodule Claude\.Hooks\.PreToolUse\.BashValidator do/
      assert content =~ ~r/event: :pre_tool_use/
      assert content =~ ~r/matcher: :bash/
      assert content =~ ~r/@impl Claude\.Hook/
      assert content =~ ~r/def handle\(input\) do/
    end

    test "generates a notification hook module" do
      hook_name = "CustomNotifier"

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          hook_name,
          "--event",
          "notification",
          "--description",
          "Custom notification handler",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/notification/custom_notifier.ex")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.Notification.CustomNotifier"
        )
      )

      source =
        Rewrite.source!(igniter.rewrite, "lib/claude/hooks/notification/custom_notifier.ex")

      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/defmodule Claude\.Hooks\.Notification\.CustomNotifier do/
      assert content =~ ~r/event: :notification/
      refute content =~ ~r/matcher:/
      assert content =~ ~r/@impl Claude\.Hook/
      assert content =~ ~r/def handle\(input\) do/
    end

    test "generates a user_prompt_submit hook module" do
      hook_name = "PromptEnhancer"

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          hook_name,
          "--event",
          "user_prompt_submit",
          "--description",
          "Enhance user prompts with context",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/user_prompt_submit/prompt_enhancer.ex")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.UserPromptSubmit.PromptEnhancer"
        )
      )

      source =
        Rewrite.source!(igniter.rewrite, "lib/claude/hooks/user_prompt_submit/prompt_enhancer.ex")

      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/defmodule Claude\.Hooks\.UserPromptSubmit\.PromptEnhancer do/
      assert content =~ ~r/@impl Claude\.Hook/
      assert content =~ ~r/def handle\(input\) do/
    end

    test "generates a stop hook module" do
      hook_name = "SessionCleanup"

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          hook_name,
          "--event",
          "stop",
          "--description",
          "Clean up after session",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/stop/session_cleanup.ex")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.Stop.SessionCleanup"
        )
      )

      source = Rewrite.source!(igniter.rewrite, "lib/claude/hooks/stop/session_cleanup.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/defmodule Claude\.Hooks\.Stop\.SessionCleanup do/
      assert content =~ ~r/@impl Claude\.Hook/
      assert content =~ ~r/def handle\(input\) do/
    end

    test "generates a subagent_stop hook module" do
      hook_name = "SubagentLogger"

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          hook_name,
          "--event",
          "subagent_stop",
          "--description",
          "Log subagent completion",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/subagent_stop/subagent_logger.ex")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.SubagentStop.SubagentLogger"
        )
      )
    end

    test "generates a pre_compact hook module" do
      hook_name = "CompactLogger"

      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          hook_name,
          "--event",
          "pre_compact",
          "--description",
          "Log before compaction",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/pre_compact/compact_logger.ex")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.PreCompact.CompactLogger"
        )
      )

      source = Rewrite.source!(igniter.rewrite, "lib/claude/hooks/pre_compact/compact_logger.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/@impl Claude\.Hook/
      assert content =~ ~r/def handle\(input\) do/
    end

    test "uses default matcher '*' when not specified for tool events" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          "AllToolsHook",
          "--event",
          "post_tool_use",
          "--description",
          "Hook for all tools",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/post_tool_use/all_tools_hook.ex")

      source =
        Rewrite.source!(igniter.rewrite, "lib/claude/hooks/post_tool_use/all_tools_hook.ex")

      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/matcher: :\*/
    end

    test "handles simple tool name matchers as atoms" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          "WriteHook",
          "--event",
          "post_tool_use",
          "--matcher",
          "write",
          "--description",
          "Hook for Write tool",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/post_tool_use/write_hook.ex")

      source = Rewrite.source!(igniter.rewrite, "lib/claude/hooks/post_tool_use/write_hook.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/matcher: :write/
    end

    test "handles complex matchers as strings" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          "ComplexHook",
          "--event",
          "post_tool_use",
          "--matcher",
          "write,edit,multi_edit",
          "--description",
          "Hook for multiple tools",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/post_tool_use/complex_hook.ex")

      source = Rewrite.source!(igniter.rewrite, "lib/claude/hooks/post_tool_use/complex_hook.ex")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/matcher: \[:write, :edit, :multi_edit\]/
    end

    test "adds hook to .claude.exs when --add-to-config is true" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.gen.hook", [
          "NewHook",
          "--event",
          "post_tool_use",
          "--description",
          "New hook to add",
          "--add-to-config",
          "true"
        ])

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/Claude\.Hooks\.PostToolUse\.NewHook/
    end

    test "warns when .claude.exs doesn't exist and --add-to-config is true" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          "NewHook",
          "--event",
          "post_tool_use",
          "--description",
          "New hook to add",
          "--add-to-config",
          "true"
        ])

      igniter
      |> assert_has_warning(&String.contains?(&1, "No .claude.exs file found"))
      |> assert_has_warning(&String.contains?(&1, "Claude.Hooks.PostToolUse.NewHook"))
    end

    test "doesn't add to config when --add-to-config is false" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.gen.hook", [
          "NewHook",
          "--event",
          "post_tool_use",
          "--description",
          "New hook not to add",
          "--no-add-to-config"
        ])

      igniter
      |> assert_unchanged(".claude.exs")
      |> assert_has_notice(
        &String.contains?(
          &1,
          "! Remember to add Claude.Hooks.PostToolUse.NewHook to your .claude.exs hooks list"
        )
      )
    end

    test "validates event type" do
      test_project()
      |> Igniter.compose_task("claude.gen.hook", ["TestHook", "--event", "invalid_event"])
      |> assert_has_issue(&String.contains?(&1, "Invalid event type: invalid_event"))
      |> assert_has_issue(&String.contains?(&1, "Valid events: post_tool_use, pre_tool_use"))
    end

    test "rejects matcher for non-tool events" do
      test_project()
      |> Igniter.compose_task("claude.gen.hook", [
        "TestHook",
        "--event",
        "notification",
        "--matcher",
        "Write"
      ])
      |> assert_has_issue(
        "The --matcher option is only valid for pre_tool_use and post_tool_use events"
      )
    end

    test "enters interactive mode when no module name provided" do
      # When no module name is provided, the task will go into interactive mode
      # In test env, it will return a cancelled notice due to :eof
      inputs = []

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.hook", ["--event", "post_tool_use"])

        assert_has_notice(igniter, &String.contains?(&1, "Hook generation cancelled"))
      end)
    end

    test "enters semi-interactive mode when module provided but no event" do
      # When module name is provided but no event, task goes into semi-interactive mode
      # In test env, it will return a cancelled notice due to :eof
      inputs = []

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.hook", ["TestHook"])

        assert_has_notice(igniter, &String.contains?(&1, "Hook generation cancelled"))
      end)
    end

    test "idempotency - doesn't duplicate hook in config" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: [
                Claude.Hooks.PostToolUse.ElixirFormatter,
                Claude.Hooks.PostToolUse.ExistingHook
              ]
            }
            """
          }
        )
        |> Igniter.compose_task("claude.gen.hook", [
          "ExistingHook",
          "--event",
          "post_tool_use",
          "--description",
          "Already exists",
          "--add-to-config",
          "true"
        ])

      igniter
      |> assert_unchanged(".claude.exs")
    end

    test "handles empty hooks list in .claude.exs" do
      igniter =
        test_project(
          files: %{
            ".claude.exs" => """
            %{
              hooks: []
            }
            """
          }
        )
        |> Igniter.compose_task("claude.gen.hook", [
          "FirstHook",
          "--event",
          "post_tool_use",
          "--description",
          "First hook to add",
          "--add-to-config",
          "true"
        ])

      source = Rewrite.source!(igniter.rewrite, ".claude.exs")
      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/Claude\.Hooks\.PostToolUse\.FirstHook/
      assert content =~ ~r/hooks:\s*\[.*\]/s
    end

    test "success notice includes all relevant information" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          "DetailedHook",
          "--event",
          "pre_tool_use",
          "--matcher",
          "Bash|Write",
          "--description",
          "Detailed hook for testing",
          "--no-add-to-config"
        ])

      igniter
      |> assert_has_notice(
        &String.contains?(
          &1,
          "Successfully generated hook module: Claude.Hooks.PreToolUse.DetailedHook"
        )
      )
      |> assert_has_notice(
        &String.contains?(&1, "Location: lib/claude/hooks/pre_tool_use/detailed_hook.ex")
      )
      |> assert_has_notice(&String.contains?(&1, "Event: pre_tool_use"))
      |> assert_has_notice(&String.contains?(&1, "Matcher: Bash|Write"))
      |> assert_has_notice(&String.contains?(&1, "Description: Detailed hook for testing"))
      |> assert_has_notice(&String.contains?(&1, "Next steps:"))
      |> assert_has_notice(&String.contains?(&1, "1. Implement your hook logic"))
      |> assert_has_notice(&String.contains?(&1, "2. Run `mix claude.install`"))
      |> assert_has_notice(&String.contains?(&1, "3. Test your hook"))
    end

    test "handles module name with multiple parts" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          "MyApp.Custom.Hook",
          "--event",
          "post_tool_use",
          "--description",
          "Namespaced hook",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/my_app/custom/hook.ex")
      |> assert_has_notice(&String.contains?(&1, "MyApp.Custom.Hook"))

      source =
        Rewrite.source!(igniter.rewrite, "lib/my_app/custom/hook.ex")

      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/defmodule MyApp\.Custom\.Hook do/
    end

    test "uses Claude namespace for simple module names" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", [
          "SimpleHook",
          "--event",
          "post_tool_use",
          "--description",
          "Simple namespaced hook",
          "--no-add-to-config"
        ])

      igniter
      |> assert_creates("lib/claude/hooks/post_tool_use/simple_hook.ex")
      |> assert_has_notice(&String.contains?(&1, "Claude.Hooks.PostToolUse.SimpleHook"))

      source =
        Rewrite.source!(igniter.rewrite, "lib/claude/hooks/post_tool_use/simple_hook.ex")

      content = Rewrite.Source.get(source, :content)

      assert content =~ ~r/defmodule Claude\.Hooks\.PostToolUse\.SimpleHook do/
    end
  end

  describe "interactive mode" do
    defp with_simulated_input(inputs, fun) do
      input_string = Enum.join(inputs, "\n")

      capture_io([input: input_string, capture_prompt: false], fn ->
        fun.()
      end)
    end

    test "generates hook with interactive prompts" do
      inputs = [
        "InteractiveHook",
        "1",
        "write,edit",
        "Interactive test hook",
        "y"
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.hook", [])

        igniter
        |> assert_creates("lib/claude/hooks/post_tool_use/interactive_hook.ex")
        |> assert_has_notice(
          &String.contains?(
            &1,
            "Successfully generated hook module: Claude.Hooks.PostToolUse.InteractiveHook"
          )
        )

        source =
          Rewrite.source!(igniter.rewrite, "lib/claude/hooks/post_tool_use/interactive_hook.ex")

        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/Interactive test hook/
        assert content =~ ~r/matcher: \[:write, :edit\]/
      end)
    end

    test "generates notification hook without matcher prompt" do
      inputs = [
        "NotifyHook",
        "4",
        "Notification handler",
        "n"
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.hook", [])

        igniter
        |> assert_creates("lib/claude/hooks/notification/notify_hook.ex")

        source = Rewrite.source!(igniter.rewrite, "lib/claude/hooks/notification/notify_hook.ex")
        content = Rewrite.Source.get(source, :content)

        refute content =~ ~r/matcher:/
      end)
    end

    test "uses default matcher when empty input for tool events" do
      inputs = [
        "DefaultMatcher",
        "2",
        "",
        "Test hook",
        "y"
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.hook", [])

        source =
          Rewrite.source!(igniter.rewrite, "lib/claude/hooks/pre_tool_use/default_matcher.ex")

        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/matcher: :\*/
      end)
    end

    test "handles all event types in interactive mode" do
      event_tests = [
        {"3", "user_prompt_submit"},
        {"5", "stop"},
        {"6", "subagent_stop"},
        {"7", "pre_compact"}
      ]

      for {number, event_type} <- event_tests do
        inputs = [
          "Test#{String.capitalize(event_type)}Hook",
          number,
          "Test #{event_type} hook",
          "y"
        ]

        with_simulated_input(inputs, fn ->
          igniter =
            test_project()
            |> Igniter.compose_task("claude.gen.hook", [])

          expected_path = "lib/claude/hooks/#{event_type}/test_#{event_type}_hook.ex"
          assert_creates(igniter, expected_path)
        end)
      end
    end

    test "falls back to non-interactive when module name is provided" do
      igniter =
        test_project()
        |> Igniter.compose_task("claude.gen.hook", ["NonInteractive", "--event", "post_tool_use"])

      igniter
      |> assert_creates("lib/claude/hooks/post_tool_use/non_interactive.ex")
    end
  end

  describe "semi-interactive mode" do
    test "prompts for event when module name provided but no event" do
      inputs = [
        # post_tool_use
        "1",
        # matcher
        "write,edit",
        # description
        "Formats code after editing",
        # add to config
        "y"
      ]

      with_simulated_input(inputs, fn ->
        igniter =
          test_project()
          |> Igniter.compose_task("claude.gen.hook", ["MyFormatter"])

        igniter
        |> assert_creates("lib/claude/hooks/post_tool_use/my_formatter.ex")
        |> assert_has_notice(&String.contains?(&1, "Successfully generated hook module"))

        source =
          Rewrite.source!(igniter.rewrite, "lib/claude/hooks/post_tool_use/my_formatter.ex")

        content = Rewrite.Source.get(source, :content)

        assert content =~ ~r/defmodule Claude\.Hooks\.PostToolUse\.MyFormatter do/
        assert content =~ ~r/event: :post_tool_use/
        assert content =~ ~r/matcher: \[:write, :edit\]/
      end)
    end
  end
end
