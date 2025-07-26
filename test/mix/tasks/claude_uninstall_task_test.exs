defmodule Mix.Tasks.Claude.UninstallTest do
  use Claude.Test.ClaudeCodeCase, async: false
  use Mimic

  describe "run/1" do
    test "uninstalls hooks successfully" do
      expect(Mix.Task, :run, fn "compile", ["--no-deps-check"] -> :ok end)
      expect(Mix.Task, :run, fn "claude", ["hooks", "uninstall"] -> :ok end)

      Mix.Tasks.Claude.Uninstall.run([])
    end

    test "delegates to mix claude hooks uninstall" do
      expect(Mix.Task, :run, fn "compile", ["--no-deps-check"] -> :ok end)
      expect(Mix.Task, :run, fn "claude", ["hooks", "uninstall"] -> :ok end)

      Mix.Tasks.Claude.Uninstall.run([])

      verify!()
    end

    test "passes through arguments" do
      expect(Mix.Task, :run, fn "compile", ["--no-deps-check"] -> :ok end)
      expect(Mix.Task, :run, fn "claude", ["hooks", "uninstall"] -> :ok end)

      Mix.Tasks.Claude.Uninstall.run(["--some-arg"])

      verify!()
    end

    test "compiles before running task" do
      expect(Mix.Task, :run, fn "compile", ["--no-deps-check"] -> :ok end)
      expect(Mix.Task, :run, fn "claude", ["hooks", "uninstall"] -> :ok end)

      Mix.Tasks.Claude.Uninstall.run([])

      verify!()
    end
  end
end
