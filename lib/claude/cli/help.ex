defmodule Claude.CLI.Help do
  @moduledoc """
  Displays help information for Claude CLI commands.
  """

  alias Claude.Utils.Shell

  def run(_args) do
    Shell.info("""
    Claude - Opinionated Claude Code integration for Elixir projects

    Usage:
      mix claude <command> [subcommand] [options]

    Commands:
      hooks      Manage Claude Code hooks
      help       Show this help message

    Examples:
      mix claude hooks install
      mix claude hooks uninstall
      mix claude help

    For more information on a specific command:
      mix claude <command> help

    Repository: https://github.com/bradleygolden/claude
    """)

    :ok
  end
end
