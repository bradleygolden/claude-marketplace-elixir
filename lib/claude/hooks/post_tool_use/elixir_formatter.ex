defmodule Claude.Hooks.PostToolUse.ElixirFormatter do
  @moduledoc """
  Checks if Elixir files need formatting after Claude Code edits them.

  This hook runs after Write, Edit, and MultiEdit operations on .ex and .exs files,
  and alerts when formatting is needed without actually modifying the files.
  """

  use Claude.Hook,
    event: :post_tool_use,
    matcher: [:write, :edit, :multi_edit],
    description: "Checks if Elixir files need formatting after Claude edits them"

  alias Claude.Hooks.Helpers

  @impl true
  def handle(%Claude.Hooks.Events.PostToolUse.Input{} = input) do
    case input.tool_input do
      %{file_path: path} when is_binary(path) ->
        if Path.extname(path) in [".ex", ".exs"] do
          format_file(path)
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp format_file(file_path) do
    case Helpers.system_cmd("mix", ["format", "--check-formatted", file_path],
           file_path: file_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, exit_code} ->
        if exit_code == 1 do
          {:block, "File needs formatting: #{file_path}. Run 'mix format #{file_path}' to fix."}
        else
          {:block, "Mix format check failed: #{output}"}
        end
    end
  rescue
    error ->
      {:error, "Format check error: #{inspect(error)}"}
  end
end
