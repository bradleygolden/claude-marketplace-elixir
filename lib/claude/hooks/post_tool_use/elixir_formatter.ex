defmodule Claude.Hooks.PostToolUse.ElixirFormatter do
  @moduledoc """
  Checks if Elixir files need formatting after Claude Code edits them.

  This hook runs after Write, Edit, and MultiEdit operations on .ex and .exs files,
  and alerts when formatting is needed without actually modifying the files.
  """

  @behaviour Claude.Hooks.Hook.Behaviour

  @edit_tools ["Edit", "Write", "MultiEdit"]
  @elixir_extensions [".ex", ".exs"]

  @impl Claude.Hooks.Hook.Behaviour
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "cd $CLAUDE_PROJECT_DIR && mix claude hooks run post_tool_use.elixir_formatter"
    }
  end

  @impl Claude.Hooks.Hook.Behaviour
  def description do
    "Checks if Elixir files need formatting after Claude edits them"
  end

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
            IO.puts(:stderr, "Claude format hook error: #{reason}")
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
    if Enum.any?(@elixir_extensions, &String.ends_with?(file_path, &1)) do
      :ok
    else
      {:skip, :not_elixir_file}
    end
  end

  defp format_file(file_path) do
    project_dir = System.get_env("CLAUDE_PROJECT_DIR") || Path.dirname(file_path)
    original_dir = File.cwd!()

    try do
      File.cd!(project_dir)

      case System.cmd("mix", ["format", "--check-formatted", file_path], stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {output, exit_code} ->
          if exit_code == 1 do
            IO.puts(:stderr, "⚠️  File needs formatting: #{file_path}")
          else
            IO.puts(:stderr, "Mix format check failed: #{output}")
          end

          :ok
      end
    rescue
      error ->
        IO.puts(:stderr, "Format check error: #{inspect(error)}")
        :ok
    after
      File.cd!(original_dir)
    end
  end
end
