defmodule TestHooks.SecurityScanner do
  @moduledoc """
  Test custom hook for security scanning.
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :pre_tool_use,
    matcher: :bash,
    description: "Scans commands for security issues"

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof), do: :ok

  def run(json_input) when is_binary(json_input) do
    with {:ok, data} <- Jason.decode(json_input),
         command <- get_in(data, ["tool_input", "command"]) || "" do
      if command =~ "rm -rf /" do
        {:error, "Dangerous command blocked by security scanner"}
      else
        :ok
      end
    else
      _ -> :ok
    end
  end
end
