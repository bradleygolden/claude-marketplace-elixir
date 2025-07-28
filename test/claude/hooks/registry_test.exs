defmodule Claude.Hooks.RegistryTest do
  use ExUnit.Case, async: false
  use Mimic

  alias Claude.Hooks.Registry

  describe "built_in_hooks/0" do
    test "returns only the known built-in hooks" do
      built_in = Registry.built_in_hooks()
      
      assert Claude.Hooks.PostToolUse.ElixirFormatter in built_in
      assert Claude.Hooks.PostToolUse.CompilationChecker in built_in
      assert Claude.Hooks.PreToolUse.PreCommitCheck in built_in
      assert length(built_in) == 3
    end
  end

  describe "custom_hooks/0" do
    test "returns empty list when no custom hooks are defined" do
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), "%{}")
      
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      assert Registry.custom_hooks() == []
      
      File.rm_rf!(test_dir)
    end

    test "discovers valid custom hooks from .claude.exs" do
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          ExampleHooks.CustomFormatter,
          ExampleHooks.SecurityScanner
        ]
      }
      """)
      
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      custom = Registry.custom_hooks()
      
      assert ExampleHooks.CustomFormatter in custom
      assert ExampleHooks.SecurityScanner in custom
      assert length(custom) == 2
      
      File.rm_rf!(test_dir)
    end

    test "filters out invalid hooks" do
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          ExampleHooks.CustomFormatter,
          ExampleHooks.InvalidHook,
          NonExistentModule
        ]
      }
      """)
      
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      custom = Registry.custom_hooks()
      
      assert ExampleHooks.CustomFormatter in custom
      refute ExampleHooks.InvalidHook in custom
      refute :NonExistentModule in custom
      assert length(custom) == 1
      
      File.rm_rf!(test_dir)
    end
  end

  describe "all_hooks/0" do
    test "includes both built-in and custom hooks" do
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          ExampleHooks.CustomFormatter
        ]
      }
      """)
      
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      all_hooks = Registry.all_hooks()
      
      assert Claude.Hooks.PostToolUse.ElixirFormatter in all_hooks
      assert Claude.Hooks.PostToolUse.CompilationChecker in all_hooks
      assert Claude.Hooks.PreToolUse.PreCommitCheck in all_hooks
      
      assert ExampleHooks.CustomFormatter in all_hooks
      
      assert length(all_hooks) == 4
      
      File.rm_rf!(test_dir)
    end

    test "handles duplicates between built-in and custom" do
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          Claude.Hooks.PostToolUse.ElixirFormatter,
          ExampleHooks.CustomFormatter
        ]
      }
      """)
      
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      all_hooks = Registry.all_hooks()
      
      assert Enum.uniq(all_hooks) == all_hooks
      
      count = Enum.count(all_hooks, &(&1 == Claude.Hooks.PostToolUse.ElixirFormatter))
      assert count == 1
      
      File.rm_rf!(test_dir)
    end
  end

  describe "custom_hook?/1" do
    test "returns true for custom hooks" do
      refute Registry.custom_hook?(Claude.Hooks.PostToolUse.ElixirFormatter)
      refute Registry.custom_hook?(Claude.Hooks.PostToolUse.CompilationChecker)
      refute Registry.custom_hook?(Claude.Hooks.PreToolUse.PreCommitCheck)
      
      assert Registry.custom_hook?(ExampleHooks.CustomFormatter)
      assert Registry.custom_hook?(ExampleHooks.SecurityScanner)
    end
  end

  describe "hook validation" do
    test "validates hooks implement required callbacks" do
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          ExampleHooks.CustomFormatter,
          ExampleHooks.InvalidHook,
          "not_a_module",
          123,
          nil,
          UnknownModule
        ]
      }
      """)
      
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      custom = Registry.custom_hooks()
      
      assert custom == [ExampleHooks.CustomFormatter]
      
      File.rm_rf!(test_dir)
    end
  end

  describe "find_by_identifier/1" do
    test "finds custom hooks by identifier" do
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          ExampleHooks.CustomFormatter
        ]
      }
      """)
      
      stub(Claude.Core.Project, :root, fn -> test_dir end)
      
      identifier = "example_hooks.custom_formatter"
      
      assert Registry.find_by_identifier(identifier) == ExampleHooks.CustomFormatter
      
      File.rm_rf!(test_dir)
    end
  end
end