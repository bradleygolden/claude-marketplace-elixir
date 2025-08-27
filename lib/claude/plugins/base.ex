defmodule Claude.Plugins.Base do
  @moduledoc "Base configuration plugin providing standard hooks and Meta Agent for Claude Code."

  @behaviour Claude.Plugin

  def config(_opts) do
    %{
      hooks: %{
        stop: [:compile, :format],
        subagent_stop: [:compile, :format],
        post_tool_use: [:compile, :format],
        pre_tool_use: [:compile, :format, :unused_deps]
      }
    }
  end
end
