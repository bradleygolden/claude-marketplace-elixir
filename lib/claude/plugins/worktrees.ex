defmodule Claude.Plugins.Worktrees do
  @moduledoc "Plugin for git worktree workflows with automatic dependency management."

  @behaviour Claude.Plugin

  def config(_opts) do
    %{
      auto_install_deps?: true
    }
  end
end
