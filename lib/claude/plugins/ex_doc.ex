defmodule Claude.Plugins.ExDoc do
  @moduledoc """
  ExDoc plugin for Claude Code providing documentation generation on pre-commit.

  This plugin automatically runs `mix docs` before git commits to ensure documentation
  is generated and up-to-date.

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.ExDoc]
      }

  This will run `mix docs` before every git commit.
  """

  @behaviour Claude.Plugin

  @impl Claude.Plugin
  def detect(nil), do: Code.ensure_loaded?(ExDoc)
  def detect(igniter), do: Igniter.Project.Deps.has_dep?(igniter, :ex_doc)

  @impl Claude.Plugin
  def config(_opts) do
    %{
      hooks: %{
        pre_tool_use: [
          {"docs --warnings-as-errors", when: "Bash", command: ~r/^git commit/}
        ]
      }
    }
  end
end
