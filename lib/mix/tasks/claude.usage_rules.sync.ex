defmodule Mix.Tasks.Claude.UsageRules.Sync do
  @shortdoc "Sync usage rules to CLAUDE.md"

  @moduledoc """
  Sync usage rules from dependencies to CLAUDE.md.

  This task uses usage_rules to update the CLAUDE.md file with:
  - Usage rules from Elixir core
  - Usage rules from OTP
  - Usage rules from all dependencies that provide them

  ## Usage

      mix claude.usage_rules.sync

  This task is automatically run as part of `mix igniter.install claude`.
  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix claude.usage_rules.sync",
      only: [:dev]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> Igniter.add_notice("""
    Syncing usage rules to CLAUDE.md...

    This will help Claude Code understand how to use your project's dependencies.
    """)
    |> Igniter.add_task("usage_rules.sync", ["CLAUDE.md", "--all", "--link-to-folder", "deps"])
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false
end
