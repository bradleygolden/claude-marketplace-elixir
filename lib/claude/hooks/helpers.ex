defmodule Claude.Hooks.Helpers do
  @moduledoc """
  Helper functions for implementing Claude Code hooks.

  This module provides common patterns and utilities to reduce boilerplate
  in hook implementations.
  """

  @edit_tools ["Edit", "Write", "MultiEdit"]

  @doc """
  Parses JSON input into the appropriate event struct.

  Returns {:ok, parsed_input} or {:error, reason}.
  """
  def parse_input(json_input, event_type) do
    case event_type do
      :post_tool_use ->
        Claude.Hooks.Events.PostToolUse.Input.from_json(json_input)

      :pre_tool_use ->
        Claude.Hooks.Events.PreToolUse.Input.from_json(json_input)

      :notification ->
        Claude.Hooks.Events.Notification.Input.from_json(json_input)

      :user_prompt_submit ->
        Claude.Hooks.Events.UserPromptSubmit.Input.from_json(json_input)

      :stop ->
        Claude.Hooks.Events.Stop.Input.from_json(json_input)

      :subagent_stop ->
        Claude.Hooks.Events.SubagentStop.Input.from_json(json_input)

      :pre_compact ->
        Claude.Hooks.Events.PreCompact.Input.from_json(json_input)

      _ ->
        {:error, "Unknown event type: #{event_type}"}
    end
  end

  @doc """
  Checks if the tool is one of the edit tools (Edit, Write, MultiEdit).
  """
  def edit_tool?(tool_name) do
    tool_name in @edit_tools
  end

  @doc """
  Extracts the file path from tool input, handling different tool types.

  Returns {:ok, file_path} or {:error, :no_file_path}.
  """
  def extract_file_path(%Claude.Hooks.ToolInputs.Edit{file_path: file_path})
      when is_binary(file_path) do
    {:ok, file_path}
  end

  def extract_file_path(%Claude.Hooks.ToolInputs.Write{file_path: file_path})
      when is_binary(file_path) do
    {:ok, file_path}
  end

  def extract_file_path(%Claude.Hooks.ToolInputs.MultiEdit{file_path: file_path})
      when is_binary(file_path) do
    {:ok, file_path}
  end

  def extract_file_path(%{} = raw_map) do
    case Map.get(raw_map, "file_path") do
      file_path when is_binary(file_path) -> {:ok, file_path}
      _ -> {:error, :no_file_path}
    end
  end

  def extract_file_path(_), do: {:error, :no_file_path}

  @doc """
  Checks if a file has one of the given extensions.

  ## Examples

      iex> has_extension?("foo.ex", [".ex", ".exs"])
      true
      
      iex> has_extension?("foo.js", [".ex", ".exs"])
      false
  """
  def has_extension?(file_path, extensions) when is_list(extensions) do
    Enum.any?(extensions, &String.ends_with?(file_path, &1))
  end

  @doc """
  Runs a function in the project directory, automatically changing back afterward.

  The project directory is determined from the CLAUDE_PROJECT_DIR environment
  variable, or falls back to the directory of the given file.
  """
  def in_project_dir(file_path \\ nil, fun) do
    project_dir =
      System.get_env("CLAUDE_PROJECT_DIR") ||
        (file_path && Path.dirname(file_path)) ||
        File.cwd!()

    original_dir = File.cwd!()

    try do
      File.cd!(project_dir)
      fun.()
    after
      File.cd!(original_dir)
    end
  end

  @doc """
  Runs a command and returns a standardized result.

  Options:
    - :cd - Directory to run the command in
    - :check_exit - Whether to check exit code (default: true)
    - :stderr_to_stdout - Redirect stderr to stdout (default: true)

  Returns :ok, {:error, output}, or {:warning, output}.
  """
  def run_command(command, args, opts \\ []) do
    dir = Keyword.get(opts, :cd)
    check_exit = Keyword.get(opts, :check_exit, true)
    stderr_to_stdout = Keyword.get(opts, :stderr_to_stdout, true)

    fun = fn ->
      case System.cmd(command, args, stderr_to_stdout: stderr_to_stdout) do
        {_output, 0} ->
          :ok

        {output, _exit_code} ->
          if check_exit do
            {:error, output}
          else
            {:warning, output}
          end
      end
    end

    if dir do
      in_project_dir(dir, fun)
    else
      fun.()
    end
  end

  @doc """
  Safely prints to stderr with a prefix.
  """
  def print_error(message, prefix \\ "Hook error") do
    IO.puts(:stderr, "#{prefix}: #{message}")
  end

  @doc """
  Safely prints a warning to stderr.
  """
  def print_warning(message, prefix \\ "⚠️") do
    IO.puts(:stderr, "#{prefix}  #{message}")
  end

  @doc """
  Pattern matches on common skip conditions and returns :ok.

  Useful for handling cases where a hook should skip processing
  without treating it as an error.
  """
  def handle_skip({:skip, _reason}), do: :ok
  def handle_skip(:ok), do: :ok

  def handle_skip({:error, reason}) do
    print_error(reason)
    :ok
  end
end
