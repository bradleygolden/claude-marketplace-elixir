defmodule Claude.Hooks.PostToolUse.CompilationChecker do
  @moduledoc """
  Pipeline-style compilation checker for Claude Code hooks.

  Uses exit codes to communicate with Claude Code:
  - Exit 0: Success (no output)
  - Exit 2: Compilation issues (stderr shown to Claude)
  """

  @doc """
  Main entry point for the compilation checker.
  """
  def run(:eof), do: :ok

  def run(input) do
    input
    |> parse_input()
    |> validate_tool()
    |> check_file_extension()
    |> run_compilation()
    |> format_response()
    |> output_and_exit()
  end

  defp parse_input(input) do
    case Claude.Hooks.Events.PostToolUse.Input.from_json(input) do
      {:ok, event} ->
        {:ok, event}

      {:error, _} ->
        {:error, "Invalid JSON input"}
    end
  end

  defp validate_tool({:error, _} = error), do: error

  defp validate_tool({:ok, %Claude.Hooks.Events.PostToolUse.Input{tool_name: tool_name} = input})
       when tool_name in ["Write", "Edit", "MultiEdit"] do
    {:ok, input}
  end

  defp validate_tool({:ok, _}), do: {:skip, "Not an edit tool"}

  defp check_file_extension({:error, _} = error), do: error
  defp check_file_extension({:skip, _} = skip), do: skip

  defp check_file_extension(
         {:ok, %Claude.Hooks.Events.PostToolUse.Input{tool_input: tool_input} = input}
       ) do
    case tool_input do
      %{file_path: path} when is_binary(path) ->
        if String.ends_with?(path, [".ex", ".exs"]) do
          {:ok, input}
        else
          {:skip, "Not an Elixir file"}
        end

      _ ->
        {:skip, "No file path"}
    end
  end

  defp run_compilation({:error, _} = error), do: error
  defp run_compilation({:skip, _} = skip), do: skip

  defp run_compilation({:ok, %Claude.Hooks.Events.PostToolUse.Input{cwd: cwd}}) do
    case System.cmd("mix", ["compile", "--warnings-as-errors"],
           cd: cwd,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :success

      {output, _exit_code} ->
        {:compilation_failed, output}
    end
  end

  defp format_response(:success), do: :success
  defp format_response({:skip, _}), do: :skip
  defp format_response({:error, _}), do: :error
  defp format_response({:compilation_failed, output}), do: {:compilation_failed, output}

  defp output_and_exit(:success) do
    System.halt(0)
  end

  defp output_and_exit(:skip) do
    System.halt(0)
  end

  defp output_and_exit(:error) do
    System.halt(0)
  end

  defp output_and_exit({:compilation_failed, output}) do
    IO.puts(:stderr, "Compilation issues detected:")
    IO.puts(:stderr, output)
    System.halt(2)
  end
end
