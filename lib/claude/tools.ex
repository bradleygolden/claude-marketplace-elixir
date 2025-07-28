defmodule Claude.Tools do
  @moduledoc """
  Defines available tools for Claude Code and provides conversion utilities.

  Tools are represented as atoms internally and converted to/from strings
  when interfacing with Claude Code.
  """

  @all_tools [
    :bash,
    :edit,
    :glob,
    :grep,
    :ls,
    :multi_edit,
    :notebook_edit,
    :notebook_read,
    :read,
    :task,
    :todo_write,
    :web_fetch,
    :web_search,
    :write
  ]

  @tools_requiring_permission [
    :bash,
    :edit,
    :multi_edit,
    :notebook_edit,
    :web_fetch,
    :web_search,
    :write
  ]

  @atom_to_string %{
    bash: "Bash",
    edit: "Edit",
    glob: "Glob",
    grep: "Grep",
    ls: "LS",
    multi_edit: "MultiEdit",
    notebook_edit: "NotebookEdit",
    notebook_read: "NotebookRead",
    read: "Read",
    task: "Task",
    todo_write: "TodoWrite",
    web_fetch: "WebFetch",
    web_search: "WebSearch",
    write: "Write"
  }

  @string_to_atom Map.new(@atom_to_string, fn {k, v} -> {v, k} end)

  @type tool :: unquote(Enum.reduce(@all_tools, &{:|, [], [&1, &2]}))

  @doc "Returns all available tool atoms"
  def all_tools, do: @all_tools

  @doc "Returns tools that require permission"
  def tools_requiring_permission, do: @tools_requiring_permission

  @doc "Converts a tool atom to Claude Code string format"
  def tool_to_string(tool) when tool in @all_tools do
    @atom_to_string[tool]
  end

  @doc "Converts a Claude Code string to tool atom"
  def from_string(string) when is_binary(string) do
    case @string_to_atom[string] do
      nil -> {:error, "Unknown tool: #{string}"}
      atom -> {:ok, atom}
    end
  end

  @doc "Converts a Claude Code string to tool atom, raising on error"
  def from_string!(string) do
    case from_string(string) do
      {:ok, tool} -> tool
      {:error, msg} -> raise ArgumentError, msg
    end
  end

  @doc "Validates a list of tool atoms"
  def validate_tools(tools) when is_list(tools) do
    invalid_tools = Enum.reject(tools, &(&1 in @all_tools))

    case invalid_tools do
      [] -> :ok
      tools -> {:error, "Invalid tools: #{Enum.join(tools, ", ")}"}
    end
  end

  @doc "Checks if a tool requires permission"
  def requires_permission?(tool) when tool in @all_tools do
    tool in @tools_requiring_permission
  end

  @doc "Converts a list of tool atoms to Claude Code strings"
  def to_strings(tools) when is_list(tools) do
    Enum.map(tools, &tool_to_string/1)
  end

  @doc "Converts a list of Claude Code strings to tool atoms"
  def from_strings(strings) when is_list(strings) do
    results = Enum.map(strings, &from_string/1)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, Enum.map(results, fn {:ok, tool} -> tool end)}
      error -> error
    end
  end
end
