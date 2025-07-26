defmodule Claude.CLITest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias Claude.CLI

  describe "main/1" do
    test "shows help when no arguments provided" do
      output =
        capture_io(fn ->
          assert CLI.main([]) == :ok
        end)

      assert output =~ "Claude - Opinionated Claude Code integration"
      assert output =~ "Commands:"
      assert output =~ "hooks"
    end

    test "shows help for help command" do
      output =
        capture_io(fn ->
          assert CLI.main(["help"]) == :ok
        end)

      assert output =~ "Claude - Opinionated Claude Code integration"
    end

    test "delegates to hooks module" do
      output =
        capture_io(fn ->
          assert CLI.main(["hooks"]) == :ok
        end)

      assert output =~ "Claude Hooks"
    end

    test "delegates to hooks install" do
      output =
        capture_io(fn ->
          CLI.main(["hooks", "install"])
        end)

      assert output =~ "installed successfully" or output =~ "Installing Claude hooks"
    end

    test "returns error for unknown command" do
      # Capture stdout to prevent help message from leaking
      stdout_output =
        capture_io(fn ->
          stderr_output =
            capture_io(:stderr, fn ->
              assert {:error, :unknown_command} = CLI.main(["unknown"])
            end)

          assert stderr_output =~ "Unknown command: unknown"
        end)

      # The help message is shown on stdout
      assert stdout_output =~ "Available commands:"
    end
  end
end
