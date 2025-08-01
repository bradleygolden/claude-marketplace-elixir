defmodule Claude.Hooks.PostToolUse.CompilationChecker do
  @moduledoc """
  Checks for compilation errors after Claude Code edits Elixir files.

  This hook runs after Write, Edit, and MultiEdit operations on .ex and .exs files.
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:write, :edit, :multi_edit],
    description: "Checks for compilation errors after Claude edits Elixir files"

  alias Claude.Hooks.{Helpers, JsonOutput}

  @elixir_extensions [".ex", ".exs"]

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof), do: :ok

  def run(json_input) when is_binary(json_input) do
    case Claude.Hooks.Events.PostToolUse.Input.from_json(json_input) do
      {:ok, %Claude.Hooks.Events.PostToolUse.Input{} = input} ->
        with :ok <- validate_tool(input.tool_name),
             {:ok, file_path} <- extract_file_path(input.tool_input),
             :ok <- validate_elixir_file(file_path) do
          check_compilation(file_path)
        else
          {:skip, _reason} ->
            JsonOutput.success(suppress_output: true)
            |> JsonOutput.write_and_exit()

          {:error, reason} ->
            # Use JSON output to provide feedback to Claude
            JsonOutput.block_post_tool("Claude compilation check error: #{reason}")
            |> JsonOutput.write_and_exit()
        end

      {:error, _} ->
        JsonOutput.success(suppress_output: true)
        |> JsonOutput.write_and_exit()
    end
  end

  defp validate_tool(tool_name) do
    if tool_name in Helpers.edit_tools() do
      :ok
    else
      {:skip, :not_edit_tool}
    end
  end

  defp extract_file_path(tool_input) do
    Helpers.extract_file_path(tool_input)
  end

  defp validate_elixir_file(file_path) do
    if Helpers.has_extension?(file_path, @elixir_extensions) do
      :ok
    else
      {:skip, :not_elixir_file}
    end
  end

  defp check_compilation(file_path) do
    Helpers.in_project_dir(file_path, fn ->
      case System.cmd("mix", ["compile", "--warnings-as-errors"], stderr_to_stdout: true) do
        {_output, 0} ->
          # Compilation successful
          JsonOutput.success(suppress_output: true)
          |> JsonOutput.write_and_exit()

        {output, _exit_code} ->
          # Compilation issues detected - provide feedback to Claude
          JsonOutput.block_post_tool("Compilation issues detected:\n#{output}")
          |> JsonOutput.write_and_exit()
      end
    end)
  rescue
    error ->
      JsonOutput.block_post_tool("Compilation check error: #{inspect(error)}")
      |> JsonOutput.write_and_exit()
  end
end
