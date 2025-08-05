defmodule Claude.Hooks.PostToolUse.ElixirFormatter do
  @moduledoc """
  Checks if Elixir files need formatting after Claude Code edits them.

  This hook runs after Write, Edit, and MultiEdit operations on .ex and .exs files,
  and alerts when formatting is needed without actually modifying the files.
  """

  @doc """
  Pipeline-style formatter checker for Claude Code hooks.
  """
  def run(:eof), do: :ok

  def run(input) do
    input
    |> parse_input()
    |> validate_tool()
    |> check_file_extension()
    |> check_formatting()
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

  defp check_formatting({:error, _} = error), do: error
  defp check_formatting({:skip, _} = skip), do: skip

  defp check_formatting(
         {:ok, %Claude.Hooks.Events.PostToolUse.Input{cwd: cwd, tool_input: tool_input}}
       ) do
    file_path = tool_input.file_path

    case System.cmd("mix", ["format", "--check-formatted", file_path],
           cd: cwd,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :success

      {_output, 1} ->
        {:needs_formatting, file_path}

      {output, _exit_code} ->
        {:format_check_failed, output}
    end
  end

  defp format_response(:success), do: :success
  defp format_response({:skip, _}), do: :skip
  defp format_response({:error, _}), do: :error
  defp format_response({:needs_formatting, file_path}), do: {:needs_formatting, file_path}
  defp format_response({:format_check_failed, output}), do: {:format_check_failed, output}

  defp output_and_exit(:success) do
    System.halt(0)
  end

  defp output_and_exit(:skip) do
    System.halt(0)
  end

  defp output_and_exit(:error) do
    System.halt(0)
  end

  defp output_and_exit({:needs_formatting, file_path}) do
    IO.puts(:stderr, "File needs formatting: #{file_path}. Run 'mix format #{file_path}' to fix.")
    System.halt(2)
  end

  defp output_and_exit({:format_check_failed, output}) do
    IO.puts(:stderr, "Mix format check failed:")
    IO.puts(:stderr, output)
    System.halt(2)
  end
end
