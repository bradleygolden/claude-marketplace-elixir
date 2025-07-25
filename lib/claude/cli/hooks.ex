defmodule Claude.CLI.Hooks do
  @moduledoc """
  Handles hooks-related CLI commands.
  """

  alias Claude.CLI.Hooks.{Install, Uninstall, Run}
  alias Claude.Utils.Shell

  @subcommands %{
    "install" => Install,
    "uninstall" => Uninstall,
    "run" => Run
  }

  def run([]), do: run(["help"])

  def run(["help" | _]) do
    Shell.info("""
    Claude Hooks - Manage Claude Code hooks for Elixir development

    Usage:
      mix claude hooks <subcommand>

    Subcommands:
      install    Install all Claude hooks
      uninstall  Remove Claude hooks from the project

    Current hooks:
      - Auto-formatting after edits
      - Compilation checking to catch errors

    Examples:
      mix claude hooks install
      mix claude hooks uninstall
    """)

    :ok
  end

  def run([subcommand | args]) do
    case @subcommands[subcommand] do
      nil ->
        Shell.error("Unknown hooks command: #{subcommand}")
        run(["help"])
        {:error, :unknown_subcommand}

      module ->
        module.run(args)
    end
  end
end
