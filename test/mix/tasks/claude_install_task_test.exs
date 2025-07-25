defmodule Mix.Tasks.Claude.InstallTest do
  use ExUnit.Case, async: false
  use Mimic

  describe "run/1" do
    test "installs hooks successfully" do
      expect(Mix.Task, :run, fn "compile", ["--no-deps-check"] -> :ok end)
      expect(Mix.Task, :run, fn "claude", ["hooks", "install"] -> :ok end)

      Mix.Tasks.Claude.Install.run([])
    end

    test "delegates to mix claude hooks install" do
      expect(Mix.Task, :run, fn "compile", ["--no-deps-check"] -> :ok end)
      expect(Mix.Task, :run, fn "claude", ["hooks", "install"] -> :ok end)

      Mix.Tasks.Claude.Install.run([])

      verify!()
    end

    test "passes through arguments" do
      expect(Mix.Task, :run, fn "compile", ["--no-deps-check"] -> :ok end)
      expect(Mix.Task, :run, fn "claude", ["hooks", "install"] -> :ok end)

      Mix.Tasks.Claude.Install.run(["--some-arg"])

      verify!()
    end
  end
end
