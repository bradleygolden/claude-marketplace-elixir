defmodule Claude.Hooks.Helpers do
  @moduledoc """
  Helper functions for implementing Claude Code hooks.
  """

  @edit_tools ["Edit", "Write", "MultiEdit"]

  @doc """
  Returns the list of edit tool names.
  """
  def edit_tools, do: @edit_tools

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
      _ -> {:skip, :no_file_path}
    end
  end

  def extract_file_path(_), do: {:skip, :no_file_path}

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
