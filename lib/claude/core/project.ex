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

  defp root do
    File.cwd!()
  end
end
