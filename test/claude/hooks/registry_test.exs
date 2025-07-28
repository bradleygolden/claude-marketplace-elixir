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
      # Create a temporary .claude.exs without hooks
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), "%{}")
      
      # Mock the project root
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      assert Registry.custom_hooks() == []
      
      File.rm_rf!(test_dir)
    end

    test "discovers valid custom hooks from .claude.exs" do
      # Create a temporary .claude.exs with custom hooks
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
      
      # Mock the project root
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      custom = Registry.custom_hooks()
      
      assert ExampleHooks.CustomFormatter in custom
      assert ExampleHooks.SecurityScanner in custom
      assert length(custom) == 2
      
      File.rm_rf!(test_dir)
    end

    test "filters out invalid hooks" do
      # Create a temporary .claude.exs with invalid hooks
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
      
      # Mock the project root
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
      # Create a temporary .claude.exs with custom hooks
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
      
      # Mock the project root
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      all_hooks = Registry.all_hooks()
      
      # Built-in hooks
      assert Claude.Hooks.PostToolUse.ElixirFormatter in all_hooks
      assert Claude.Hooks.PostToolUse.CompilationChecker in all_hooks
      assert Claude.Hooks.PreToolUse.PreCommitCheck in all_hooks
      
      # Custom hook
      assert ExampleHooks.CustomFormatter in all_hooks
      
      assert length(all_hooks) == 4
      
      File.rm_rf!(test_dir)
    end

    test "handles duplicates between built-in and custom" do
      # Create a temporary .claude.exs that includes a built-in hook
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
      
      # Mock the project root
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      all_hooks = Registry.all_hooks()
      
      # Should not have duplicates
      assert Enum.uniq(all_hooks) == all_hooks
      
      # ElixirFormatter should appear only once
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
      # Create a temporary .claude.exs with various hook types
      _original_root = Claude.Core.Project.root()
      temp_dir = System.tmp_dir!()
      test_dir = Path.join([temp_dir, "claude_test_#{:rand.uniform(10000)}"])
      File.mkdir_p!(test_dir)
      
      File.write!(Path.join(test_dir, ".claude.exs"), """
      %{
        hooks: [
          ExampleHooks.CustomFormatter,      # Valid
          ExampleHooks.InvalidHook,          # Invalid - missing callbacks
          "not_a_module",                    # Invalid - not an atom
          123,                               # Invalid - not an atom
          nil,                               # Invalid - nil
          UnknownModule                      # Invalid - doesn't exist
        ]
      }
      """)
      
      # Mock the project root
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      custom = Registry.custom_hooks()
      
      # Only the valid hook should be included
      assert custom == [ExampleHooks.CustomFormatter]
      
      File.rm_rf!(test_dir)
    end
  end

  describe "find_by_identifier/1" do
    test "finds custom hooks by identifier" do
      # Create a temporary .claude.exs with custom hooks
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
      
      # Mock the project root
      expect(Claude.Core.Project, :root, fn -> test_dir end)
      
      # The identifier for the custom hook
      identifier = Registry.hook_identifier(ExampleHooks.CustomFormatter)
      
      # Should find the custom hook
      assert Registry.find_by_identifier(identifier) == ExampleHooks.CustomFormatter
      
      File.rm_rf!(test_dir)
    end
  end
end