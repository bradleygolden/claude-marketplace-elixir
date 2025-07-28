defmodule Mix.Tasks.Claude.Subagents.List do
  @moduledoc """
  Lists configured Claude subagents from .claude.exs.

  ## Usage

      mix claude.subagents.list
  """

  use Mix.Task

  alias Claude.Core.ClaudeExs
  alias Claude.Tools
  alias Claude.Utils.Shell

  @shortdoc "List configured subagents"

  @impl Mix.Task
  def run(_args) do
    case ClaudeExs.load() do
      {:ok, config} ->
        subagents = ClaudeExs.get_subagents(config)
        display_subagents(subagents)

      {:error, :not_found} ->
        Shell.error("No .claude.exs file found")
        {:error, "No .claude.exs file found"}

      {:error, reason} ->
        Shell.error("Failed to load .claude.exs: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp display_subagents([]) do
    Shell.info("No subagents configured in .claude.exs")
  end

  defp display_subagents(subagents) do
    Shell.info("Configured subagents:")
    Shell.blank()

    Enum.each(subagents, &display_subagent/1)
  end

  defp display_subagent(config) do
    Shell.bullet(config.name)
    Shell.info("  #{config.description}")

    if config[:tools] && config[:tools] != [] do
      tools = Enum.map(config.tools, &Tools.tool_to_string/1) |> Enum.join(", ")
      Shell.info("  Tools: #{tools}")
    end

    if config[:usage_rules] && config[:usage_rules] != [] do
      Shell.info("  Usage rules: #{Enum.join(config.usage_rules, ", ")}")
    end

    Shell.blank()
  end
end
