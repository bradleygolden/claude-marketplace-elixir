defmodule Claude.Hooks.PostToolUse.ElixirFormatter do
  @moduledoc """
  Checks if Elixir files need formatting after Claude Code edits them.

  This hook runs after Write, Edit, and MultiEdit operations on .ex and .exs files,
  and alerts when formatting is needed without actually modifying the files.
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :post_tool_use,
    matcher: [:write, :edit, :multi_edit],
    description: "Checks if Elixir files need formatting after Claude edits them"

  alias Claude.Hooks.Helpers

  @edit_tools ["Edit", "Write", "MultiEdit"]
  @elixir_extensions [".ex", ".exs"]

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof), do: :ok

  def run(json_input) when is_binary(json_input) do
    case Claude.Hooks.Events.PostToolUse.Input.from_json(json_input) do
      {:ok, %Claude.Hooks.Events.PostToolUse.Input{} = input} ->
        with :ok <- validate_tool(input.tool_name),
             {:ok, file_path} <- extract_file_path(input.tool_input),
             :ok <- validate_elixir_file(file_path) do
          format_file(file_path)
        else
          {:skip, _reason} ->
            :ok

          {:error, reason} ->
            Helpers.print_error("Claude format hook error: #{reason}")
            :ok
        end

      {:error, _} ->
        :ok
    end
  end

  defp validate_tool(tool_name) when tool_name in @edit_tools, do: :ok
  defp validate_tool(_), do: {:skip, :not_edit_tool}

  defp extract_file_path(%Claude.Hooks.ToolInputs.Edit{file_path: file_path})
       when is_binary(file_path) do
    {:ok, file_path}
  end

  defp extract_file_path(%Claude.Hooks.ToolInputs.Write{file_path: file_path})
       when is_binary(file_path) do
    {:ok, file_path}
  end

  defp extract_file_path(%Claude.Hooks.ToolInputs.MultiEdit{file_path: file_path})
       when is_binary(file_path) do
    {:ok, file_path}
  end

  defp extract_file_path(%{} = raw_map) do
    case Map.get(raw_map, "file_path") do
      file_path when is_binary(file_path) -> {:ok, file_path}
      _ -> {:skip, :no_file_path}
    end
  end

  defp extract_file_path(_) do
    {:skip, :no_file_path}
  end

  defp validate_elixir_file(file_path) do
    if Helpers.has_extension?(file_path, @elixir_extensions) do
      :ok
    else
      {:skip, :not_elixir_file}
    end
  end

  defp format_file(file_path) do
    Helpers.in_project_dir(file_path, fn ->
      case System.cmd("mix", ["format", "--check-formatted", file_path], stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {output, exit_code} ->
          if exit_code == 1 do
            Helpers.print_warning("File needs formatting: #{file_path}")
          else
            Helpers.print_error("Mix format check failed: #{output}")
          end

          :ok
      end
    end)
  rescue
    error ->
      Helpers.print_error("Format check error: #{inspect(error)}")
      :ok
  end
end
