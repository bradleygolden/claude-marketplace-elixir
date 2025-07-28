defmodule Claude.Subagents.Subagent do
  @moduledoc """
  Represents a Claude Code subagent configuration.

  Subagents are specialized AI assistants that can handle specific tasks
  with their own context window and tool access.
  """

  alias Claude.Tools

  @type plugin_spec :: {module(), map()}

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          prompt: String.t(),
          tools: [Tools.tool()],
          plugins: [plugin_spec()]
        }

  defstruct [:name, :description, :prompt, tools: [], plugins: []]

  @doc """
  Creates a new Subagent from parsed attributes.

  Accepts both atom and string keys, and normalizes tool names to atoms.
  """
  def new(attrs) when is_map(attrs) do
    %__MODULE__{
      name: attrs[:name] || attrs["name"],
      description: attrs[:description] || attrs["description"],
      prompt: attrs[:prompt] || attrs["prompt"],
      tools: parse_tools(attrs[:tools] || attrs["tools"]),
      plugins: parse_plugins(attrs[:plugins] || attrs["plugins"])
    }
  end

  @doc """
  Converts the subagent's tools to Claude Code string format.
  """
  def tools_to_strings(%__MODULE__{tools: tools}) do
    Tools.to_strings(tools)
  end

  defp parse_tools(nil), do: []

  defp parse_tools(tools) when is_list(tools) do
    tools
    |> Enum.map(&parse_tool/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_tools(tools) when is_binary(tools) do
    tools
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> parse_tools()
  end

  defp parse_tool(tool) when is_atom(tool), do: tool

  defp parse_tool(tool) when is_binary(tool) do
    case Tools.from_string(tool) do
      {:ok, atom} -> atom
      _ -> nil
    end
  end

  defp parse_plugins(nil), do: []

  defp parse_plugins(plugins) when is_list(plugins) do
    plugins
    |> Enum.map(&parse_plugin/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_plugin({module, opts}) when is_atom(module) and is_map(opts) do
    {module, opts}
  end

  defp parse_plugin(_), do: nil
end
