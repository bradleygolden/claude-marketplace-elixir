defmodule Claude.Core.Project do
  @moduledoc """
  Project detection and information utilities.
  Provides common functionality for working with Elixir projects.
  """

  @claude_dir ".claude"

  @doc """
  Returns the path to the .claude directory in the current project.
  """
  def claude_path do
    Path.join(root(), @claude_dir)
  end

  @doc """
  Returns the root path of the current project.
  Checks CLAUDE_PROJECT_DIR environment variable first, then falls back to current working directory.
  """
  def root do
    System.get_env("CLAUDE_PROJECT_DIR") || File.cwd!()
  end
end
