defmodule Claude.CommandInstallerTest do
  use Claude.ClaudeCodeCase

  describe "install/1" do
    test "copies bundled commands from development location" do
      igniter = test_project()

      result = Claude.CommandInstaller.install(igniter)

      assert Enum.any?(result.rewrite.sources, fn {path, _} ->
               String.contains?(path, ".claude/commands/") and String.ends_with?(path, ".md")
             end)
    end

    test "preserves existing custom commands" do
      igniter =
        test_project(
          files: %{
            ".claude/commands/custom/my-command.md" => """
            ---
            description: My custom command
            ---
            # My Command
            Custom content
            """
          }
        )

      result = Claude.CommandInstaller.install(igniter)

      assert Igniter.exists?(result, ".claude/commands/custom/my-command.md")
    end
  end

  describe "list_bundled_commands/0" do
    test "lists available command categories and commands" do
      commands = Claude.CommandInstaller.list_bundled_commands()

      assert Map.has_key?(commands, "mix")
      assert Map.has_key?(commands, "elixir")
      assert Map.has_key?(commands, "memory")
      assert Map.has_key?(commands, "claude")

      assert "deps-upgrade" in Map.get(commands, "mix", [])
      assert "install" in Map.get(commands, "claude", [])
      assert "nested-add" in Map.get(commands, "memory", [])
    end
  end
end
