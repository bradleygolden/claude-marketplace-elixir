defmodule Mix.Tasks.Claude.Subagents do
  @moduledoc """
  Manages Claude subagents in your project.

  ## Usage

      mix claude.subagents COMMAND

  ## Commands

    * `generate` - Generate subagent markdown files from .claude.exs configuration
    * `list` - List configured subagents

  ## Examples

      # Generate all subagents
      mix claude.subagents generate

      # List configured subagents
      mix claude.subagents list
  """

  use Mix.Task

  @shortdoc "Manages Claude subagents"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      ["generate" | rest] ->
        Mix.Task.run("claude.subagents.generate", rest)

      ["list" | rest] ->
        Mix.Task.run("claude.subagents.list", rest)

      _ ->
        Mix.shell().info(@moduledoc)
    end
  end
end
