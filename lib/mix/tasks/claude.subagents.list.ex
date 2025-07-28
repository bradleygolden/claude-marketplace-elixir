defmodule Mix.Tasks.Claude.Subagents.List do
  @moduledoc """
  Lists configured Claude subagents from .claude.exs.

  ## Usage

      mix claude.subagents.list
  """

  use Igniter.Mix.Task

  alias Claude.Core.ClaudeExs
  alias Claude.Tools

  @shortdoc "List configured subagents"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix claude.subagents.list",
      only: [:dev]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    case ClaudeExs.load() do
      {:ok, config} ->
        subagents = ClaudeExs.get_subagents(config)
        message = format_subagents(subagents)
        Igniter.add_notice(igniter, message)

      {:error, :not_found} ->
        Igniter.add_warning(igniter, "No .claude.exs file found")

      {:error, reason} ->
        Igniter.add_warning(igniter, "Failed to load .claude.exs: #{inspect(reason)}")
    end
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false

  # Support direct invocation for testing and non-Igniter usage  
  def run(_args) do
    case ClaudeExs.load() do
      {:ok, config} ->
        subagents = ClaudeExs.get_subagents(config)
        display_subagents(subagents)

      {:error, :not_found} ->
        IO.puts("No subagents configured in .claude.exs")

      {:error, reason} ->
        IO.puts(:stderr, "Failed to load .claude.exs: #{inspect(reason)}")
    end
  end

  defp display_subagents([]) do
    IO.puts("No subagents configured in .claude.exs")
  end

  defp display_subagents(subagents) do
    IO.puts("Configured subagents:\n")

    Enum.each(subagents, fn config ->
      IO.puts("• #{config.name}")
      IO.puts("  #{config.description}")

      if config[:tools] && config[:tools] != [] do
        tools = Enum.map(config.tools, &Tools.tool_to_string/1) |> Enum.join(", ")
        IO.puts("  Tools: #{tools}")
      end

      if config[:usage_rules] && config[:usage_rules] != [] do
        IO.puts("  Usage rules: #{Enum.join(config.usage_rules, ", ")}")
      end

      IO.puts("")
    end)
  end

  defp format_subagents([]) do
    "No subagents configured in .claude.exs"
  end

  defp format_subagents(subagents) do
    lines = ["Configured subagents:", ""]

    subagent_lines =
      Enum.flat_map(subagents, fn config ->
        base_lines = [
          "• #{config.name}",
          "  #{config.description}"
        ]

        tool_lines =
          if config[:tools] && config[:tools] != [] do
            tools = Enum.map(config.tools, &Tools.tool_to_string/1) |> Enum.join(", ")
            ["  Tools: #{tools}"]
          else
            []
          end

        usage_rules_lines =
          if config[:usage_rules] && config[:usage_rules] != [] do
            ["  Usage rules: #{Enum.join(config.usage_rules, ", ")}"]
          else
            []
          end

        base_lines ++ tool_lines ++ usage_rules_lines ++ [""]
      end)

    (lines ++ subagent_lines)
    |> Enum.join("\n")
    |> String.trim_trailing()
  end
end
