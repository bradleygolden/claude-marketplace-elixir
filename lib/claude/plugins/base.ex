defmodule Claude.Plugins.Base do
  @moduledoc "Base configuration plugin providing standard hooks and Meta Agent for Claude Code."

  @behaviour Claude.Plugin

  @impl Claude.Plugin
  def detect(_igniter), do: true

  @impl Claude.Plugin
  def config(_opts) do
    %{
      hooks: %{
        post_tool_use: [:compile, :format],
        pre_tool_use: [:compile, :format, :unused_deps]
      }
    }
  end
end
