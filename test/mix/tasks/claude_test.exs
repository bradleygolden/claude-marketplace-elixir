defmodule Mix.Tasks.ClaudeTest do
  use Claude.Test.ClaudeCodeCase

  describe "run/1" do
    test "delegates to CLI with arguments" do
      output =
        capture_io(fn ->
          Mix.Tasks.Claude.run(["help"])
        end)

      assert output =~ "Claude - Opinionated Claude Code integration"
      assert output =~ "Commands:"
    end

    test "handles hooks install command" do
      output =
        capture_io(fn ->
          Mix.Tasks.Claude.run(["hooks", "help"])
        end)

      assert output =~ "Claude Hooks"
    end

    test "compiles project before running" do
      output =
        capture_io(fn ->
          Mix.Tasks.Claude.run([])
        end)

      assert output =~ "Claude"
    end
  end
end
