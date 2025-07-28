defmodule TestHooks.CustomFormatter do
  @moduledoc """
  Test custom hook for formatting validation.
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:write, :edit],
    description: "Custom formatter for project-specific patterns"

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof), do: :ok

  def run(json_input) when is_binary(json_input) do
    with {:ok, data} <- Jason.decode(json_input),
         file_path <- get_in(data, ["tool_input", "file_path"]) || "" do
      if String.ends_with?(file_path, ".ex") do
        IO.puts("Custom formatter processed: #{file_path}")
      end

      :ok
    else
      _ -> :ok
    end
  end
end
