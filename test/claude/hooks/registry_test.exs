defmodule Claude.Hooks.RegistryTest do
  use ExUnit.Case

  # Create test hook modules
  defmodule TestHook1 do
    @behaviour Claude.Hooks.Hook.Behaviour

    def config do
      %Claude.Hooks.Hook{
        type: "command",
        command: "test_hook_1",
        matcher: ".*"
      }
    end

    def description, do: "Test hook 1"
    def run(_, _), do: :ok
  end

  defmodule TestHook2 do
    @behaviour Claude.Hooks.Hook.Behaviour

    def config do
      %Claude.Hooks.Hook{
        type: "command",
        command: "test_hook_2",
        matcher: "Write"
      }
    end

    def description, do: "Test hook 2"
    def run(_, _), do: :ok
  end

  defmodule InvalidHook do
    # Missing behaviour implementation
    def config, do: %{}
  end

  @test_config_dir Path.join(System.tmp_dir!(), "claude_registry_test_#{:rand.uniform(999_999)}")

  setup do
    File.mkdir_p!(@test_config_dir)
    original_cwd = File.cwd!()
    File.cd!(@test_config_dir)

    on_exit(fn ->
      File.cd!(original_cwd)
      File.rm_rf!(@test_config_dir)
    end)

    :ok
  end

  describe "all_hooks/0" do
    test "returns builtin hooks when no custom hooks configured" do
      hooks = Claude.Hooks.Registry.all_hooks()

      assert Claude.Hooks.PostToolUse.ElixirFormatter in hooks
      assert Claude.Hooks.PostToolUse.CompilationChecker in hooks
      assert Claude.Hooks.PreToolUse.PreCommitCheck in hooks
    end

    test "includes custom hooks from .claude.exs" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: true
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      hooks = Claude.Hooks.Registry.all_hooks()
      assert TestHook1 in hooks
    end

    test "excludes disabled custom hooks" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: false
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      hooks = Claude.Hooks.Registry.all_hooks()
      refute TestHook1 in hooks
    end
  end

  describe "custom_hooks/0" do
    test "returns empty list when no .claude.exs" do
      assert [] == Claude.Hooks.Registry.custom_hooks()
    end

    test "filters out invalid hook modules" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: true
          },
          %{
            module: #{__MODULE__}.InvalidHook,
            enabled: true
          },
          %{
            module: NonExistentModule,
            enabled: true
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      hooks = Claude.Hooks.Registry.custom_hooks()
      assert TestHook1 in hooks
      refute InvalidHook in hooks
      refute NonExistentModule in hooks
    end
  end

  describe "find_by_identifier/1" do
    test "finds builtin hook by identifier" do
      hook = Claude.Hooks.Registry.find_by_identifier("post_tool_use.elixir_formatter")
      assert hook == Claude.Hooks.PostToolUse.ElixirFormatter
    end

    test "finds custom hook by identifier" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: true
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      hook = Claude.Hooks.Registry.find_by_identifier("registry_test.test_hook1")
      assert hook == TestHook1
    end

    test "returns nil for unknown identifier" do
      assert nil == Claude.Hooks.Registry.find_by_identifier("unknown.hook")
    end
  end

  describe "hook_module?/1" do
    test "returns true for valid hook modules" do
      assert Claude.Hooks.Registry.hook_module?(TestHook1)
      assert Claude.Hooks.Registry.hook_module?(TestHook2)
    end

    test "returns false for invalid hook modules" do
      refute Claude.Hooks.Registry.hook_module?(InvalidHook)
      refute Claude.Hooks.Registry.hook_module?(NonExistentModule)
      refute Claude.Hooks.Registry.hook_module?("not_a_module")
      refute Claude.Hooks.Registry.hook_module?(nil)
    end
  end

  describe "hook_config/1" do
    test "returns empty map when no custom config" do
      assert %{} == Claude.Hooks.Registry.hook_config(TestHook1)
    end

    test "returns custom config from .claude.exs" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: true,
            config: %{
              custom_option: "test_value",
              number: 42
            }
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      config = Claude.Hooks.Registry.hook_config(TestHook1)
      assert config.custom_option == "test_value"
      assert config.number == 42
    end
  end

  describe "group_by_event_and_matcher/1" do
    test "groups hooks correctly" do
      hooks = [TestHook1, TestHook2]
      grouped = Claude.Hooks.Registry.group_by_event_and_matcher(hooks)

      assert Map.has_key?(grouped, {"RegistryTest", ".*"})
      assert Map.has_key?(grouped, {"RegistryTest", "Write"})
      assert TestHook1 in grouped[{"RegistryTest", ".*"}]
      assert TestHook2 in grouped[{"RegistryTest", "Write"}]
    end

    test "groups hooks by configured event type" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: true,
            event_type: "PreToolUse"
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      hooks = [TestHook1, TestHook2]
      grouped = Claude.Hooks.Registry.group_by_event_and_matcher(hooks)

      # TestHook1 should be under PreToolUse due to config
      assert Map.has_key?(grouped, {"PreToolUse", ".*"})
      assert TestHook1 in grouped[{"PreToolUse", ".*"}]

      # TestHook2 should still be under RegistryTest (no config)
      assert Map.has_key?(grouped, {"RegistryTest", "Write"})
      assert TestHook2 in grouped[{"RegistryTest", "Write"}]
    end
  end

  describe "event_type_for/1" do
    test "returns configured event type from .claude.exs" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: true,
            event_type: "PreToolUse"
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      assert "PreToolUse" == Claude.Hooks.Registry.event_type_for(TestHook1)
    end

    test "falls back to module name when no event_type configured" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: true
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      # Falls back to module name inference
      assert "RegistryTest" == Claude.Hooks.Registry.event_type_for(TestHook1)
    end

    test "uses module name when hook not in config" do
      assert "RegistryTest" == Claude.Hooks.Registry.event_type_for(TestHook2)
    end
  end

  describe "hook_info/1" do
    test "returns full hook information with custom event type" do
      config_content = """
      %{
        hooks: [
          %{
            module: #{__MODULE__}.TestHook1,
            enabled: false,
            event_type: "UserPromptSubmit",
            config: %{
              custom_setting: "value"
            }
          }
        ]
      }
      """

      File.write!(".claude.exs", config_content)

      info = Claude.Hooks.Registry.hook_info(TestHook1)

      assert info.module == TestHook1
      assert info.enabled == false
      assert info.event_type == "UserPromptSubmit"
      assert info.config.custom_setting == "value"
    end

    test "returns default info for unconfigured hook" do
      info = Claude.Hooks.Registry.hook_info(TestHook2)

      assert info.module == TestHook2
      assert info.enabled == true
      assert info.event_type == "RegistryTest"
      assert info.config == %{}
    end
  end
end
