defmodule Claude.CLI.HooksTest do
  use Claude.Test.ClaudeCodeCase, async: false
  use Mimic

  import ExUnit.CaptureIO
  import Claude.TestHelpers

  alias Claude.CLI.Hooks
  alias Claude.Core.Project

  setup :verify_on_exit!

  describe "run/1" do
    test "shows help when no subcommand given" do
      output =
        capture_io(fn ->
          assert Hooks.run([]) == :ok
        end)

      assert output =~ "Claude Hooks"
      assert output =~ "Subcommands:"
      assert output =~ "install"
      assert output =~ "uninstall"
      assert output =~ "uninstall"
    end

    test "shows help with help subcommand" do
      output =
        capture_io(fn ->
          assert Hooks.run(["help"]) == :ok
        end)

      assert output =~ "Claude Hooks"
    end

    test "delegates to install" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)

        output =
          capture_io(fn ->
            assert Hooks.run(["install"]) == :ok
          end)

        assert output =~ "installed successfully" or output =~ "Installing Claude hooks"
      end)
    end

    test "delegates to uninstall" do
      in_tmp(fn tmp_dir ->
        stub(Project, :claude_path, fn -> Path.join(tmp_dir, ".claude") end)

        output =
          capture_io(fn ->
            assert Hooks.run(["uninstall"]) == :ok
          end)

        assert output =~ "No Claude hooks found" or output =~ "uninstalled successfully"
      end)
    end

    test "handles run subcommand" do
      output =
        capture_io(fn ->
          # Run with missing arguments exits silently
          Hooks.run(["run"])
        end)

      # Run command exits silently with invalid args
      assert output == ""
    end

    test "returns error for unknown subcommand" do
      output =
        capture_io(:stderr, fn ->
          assert {:error, :unknown_subcommand} = Hooks.run(["unknown"])
        end)

      assert output =~ "Unknown hooks command: unknown"
    end
  end
end
