defmodule Claude.Core.ConfigTemplate do
  @moduledoc """
  Templates for Claude configuration files.
  """

  @doc """
  Returns the default content for a new .claude.exs file.
  """
  def claude_exs_content do
    """
    # .claude.exs - Claude configuration for this project
    # This file is evaluated when Claude reads your project settings
    # and merged with .claude/settings.json (this file takes precedence)

    # You can configure various aspects of Claude's behavior here:
    # - Project metadata and context
    # - Custom behaviors and preferences
    # - Development workflow settings
    # - Code generation patterns
    # - And more as Claude evolves

    # Example configuration (uncomment and modify as needed):
    %{}
    """
  end
end
