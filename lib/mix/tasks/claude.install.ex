defmodule Mix.Tasks.Claude.Install do
  use Mix.Task

  @shortdoc "Install all Claude hooks (convenience task)"

  @moduledoc """
  Convenience task to quickly install Claude hooks for your Elixir project.

  This is equivalent to running:
      mix claude hooks install

  ## Usage

      mix claude.install

  ## What it does

  Installs all available Claude hooks including:
  - Auto-formatting for Elixir files after edits
  - Compilation checking to catch errors immediately

  Future hooks will be automatically included when available.
  """

  def run(_args) do
    Mix.Task.run("compile", ["--no-deps-check"])
    Mix.Task.run("claude", ["hooks", "install"])
  end
end
