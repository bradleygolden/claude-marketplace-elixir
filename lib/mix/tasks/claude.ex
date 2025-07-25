defmodule Mix.Tasks.Claude do
  use Mix.Task

  @shortdoc "Opinionated Claude Code integration for Elixir"

  @moduledoc """
  Entry point for Claude mix tasks.
  Delegates to the CLI module for command processing.

  Claude is an opinionated Claude Code integration for Elixir projects.

  ## Usage

      mix claude <command> [subcommand] [options]

  ## Commands

    * `hooks` - Manage Claude Code hooks
    * `help` - Show help information

  ## Examples

      mix claude hooks install
      mix claude hooks uninstall
      mix claude help

  For detailed help on any command:

      mix claude <command> help
  """

  def run(args) do
    Mix.Task.run("compile", [])
    Claude.CLI.main(args)
  end
end
