defmodule Claude.Hooks.PostToolUse.CompilationChecker do
  @moduledoc """
  Checks for compilation errors after Claude Code edits Elixir files.

  This hook runs after Write, Edit, and MultiEdit operations on .ex and .exs files.
  """

  use Claude.Hook,
    event: :post_tool_use,
    matcher: [:write, :edit, :multi_edit],
    description: "Checks for compilation errors after Claude edits Elixir files"

  alias Claude.Hooks.Helpers

  @impl true
  def handle(%Claude.Hooks.Events.PostToolUse.Input{} = input) do
    case input.tool_input do
      %{file_path: path} when is_binary(path) ->
        if Path.extname(path) in [".ex", ".exs"] do
          check_compilation(path)
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp check_compilation(file_path) do
    case Helpers.system_cmd("mix", ["compile", "--warnings-as-errors"],
           file_path: file_path,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:block, "Compilation issues detected:\n#{output}"}
    end
  rescue
    error ->
      {:error, "Compilation check error: #{inspect(error)}"}
  end
end
