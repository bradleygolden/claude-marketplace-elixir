defmodule Claude.Hooks.PostToolUse.CompilationChecker do
  @moduledoc """
  Checks for compilation errors after Claude Code edits Elixir files.

  This hook runs after Write, Edit, and MultiEdit operations on .ex and .exs files.
  """

  @behaviour Claude.Hooks.Hook.Behaviour

  @edit_tools ["Edit", "Write", "MultiEdit"]
  @elixir_extensions [".ex", ".exs"]

  @impl Claude.Hooks.Hook.Behaviour
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command:
        "cd $CLAUDE_PROJECT_DIR && mix claude hooks run post_tool_use.compilation_checker \"$1\" \"$2\"",
      matcher: ".*"
    }
  end

  @impl Claude.Hooks.Hook.Behaviour
  def description do
    "Checks for compilation errors after Claude edits Elixir files"
  end

  @impl Claude.Hooks.Hook.Behaviour
  def run(tool_name, json_params) do
    with :ok <- validate_tool(tool_name),
         {:ok, file_path} <- extract_file_path(json_params),
         :ok <- validate_elixir_file(file_path) do
      check_compilation(file_path)
    else
      {:skip, _reason} ->
        :ok

      {:error, reason} ->
        IO.puts(:stderr, "Claude compilation check error: #{reason}")
        :ok
    end
  end

  defp validate_tool(tool_name) when tool_name in @edit_tools, do: :ok
  defp validate_tool(_), do: {:skip, :not_edit_tool}

  defp extract_file_path(json_string) do
    case Jason.decode(json_string) do
      {:ok, %{"file_path" => file_path}} when is_binary(file_path) ->
        {:ok, file_path}

      _ ->
        {:skip, :no_file_path}
    end
  end

  defp validate_elixir_file(file_path) do
    if Enum.any?(@elixir_extensions, &String.ends_with?(file_path, &1)) do
      :ok
    else
      {:skip, :not_elixir_file}
    end
  end

  defp check_compilation(file_path) do
    project_dir = System.get_env("CLAUDE_PROJECT_DIR") || Path.dirname(file_path)
    original_dir = File.cwd!()

    try do
      File.cd!(project_dir)

      case System.cmd("mix", ["compile", "--warnings-as-errors"], stderr_to_stdout: true) do
        {_output, 0} ->
          :ok

        {output, _exit_code} ->
          IO.puts(:stderr, "\n⚠️  Compilation issues detected:")
          IO.puts(:stderr, output)
          :ok
      end
    rescue
      error ->
        IO.puts(:stderr, "Compilation check error: #{inspect(error)}")
        :ok
    after
      File.cd!(original_dir)
    end
  end
end
