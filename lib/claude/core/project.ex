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
  Defaults to the current working directory but can be overridden.
  """
  def root do
    # For now, use File.cwd! but this provides a single place to change
    # the logic for finding project root (e.g., looking for mix.exs)
    File.cwd!()
  end
end
