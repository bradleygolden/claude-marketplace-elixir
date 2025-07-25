defmodule Claude.CLI do
  @moduledoc """
  Main CLI entry point for Claude commands.
  Supports nested command structure for extensibility.
  """

  alias Claude.CLI.{Hooks, Help}
  alias Claude.Utils.Shell

  @commands %{
    "hooks" => Hooks,
    "help" => Help
  }

  @doc """
  Main entry point for CLI commands.
  """
  def main(args \\ []) do
    case parse_args(args) do
      {nil, _} ->
        Help.run([])

      {command, subargs} ->
        dispatch(command, subargs)
    end
  end

  defp parse_args([]), do: {nil, []}
  defp parse_args([command | rest]), do: {command, rest}

  defp dispatch(command, args) do
    case @commands[command] do
      nil ->
        Shell.error("Unknown command: #{command}")
        Shell.info("\nAvailable commands:")
        Enum.each(@commands, fn {cmd, _} -> Shell.info("  #{cmd}") end)
        {:error, :unknown_command}

      module ->
        module.run(args)
    end
  end
end
