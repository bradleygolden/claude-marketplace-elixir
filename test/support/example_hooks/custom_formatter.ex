defmodule ExampleHooks.CustomFormatter do
  @moduledoc """
  Example custom hook that formats files with a custom pattern.
  Used for testing custom hook registration and installation.
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:write, :edit],
    description: "Custom formatter for project-specific patterns"

  @impl Claude.Hooks.Hook.Behaviour
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "cd $CLAUDE_PROJECT_DIR && mix claude hooks run example_hooks.custom_formatter"
    }
  end

  @impl true
  def run(:eof), do: :ok

  def run(json_input) when is_binary(json_input) do
    with {:ok, data} <- Jason.decode(json_input),
         file_path <- get_in(data, ["tool_input", "file_path"]) || "" do
      if String.ends_with?(file_path, ".ex") or String.ends_with?(file_path, ".exs") do
        IO.puts("Custom formatter would process: #{file_path}")
      end

      :ok
    else
      _ -> :ok
    end
  end
end
