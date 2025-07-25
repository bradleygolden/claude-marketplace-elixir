defmodule Mix.Tasks.Claude.Uninstall do
  use Mix.Task

  @shortdoc "Uninstall all Claude hooks (convenience task)"

  @moduledoc """
  Convenience task to quickly uninstall Claude hooks from your Elixir project.

  This is equivalent to running:
      mix claude hooks uninstall

  ## Usage

      mix claude.uninstall

  ## What it does

  Removes all Claude-managed hooks while preserving any custom hooks
  you may have added to your .claude/settings.json file.
  """

  def run(_args) do
    Mix.Task.run("compile", ["--no-deps-check"])
    Mix.Task.run("claude", ["hooks", "uninstall"])
  end
end
