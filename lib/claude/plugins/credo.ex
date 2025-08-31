defmodule Claude.Plugins.Credo do
  @moduledoc """
  Credo plugin for Claude Code providing code quality and static analysis support.

  This plugin automatically configures Claude Code for Credo-enabled projects by:

  * **Smart Detection**: Automatically activates when Credo dependency is detected
  * **Configurable Strictness**: Control whether to run Credo in strict mode

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.Credo]
      }

  Or with options:

      %{
        plugins: [{Claude.Plugins.Credo, strict?: true}]
      }

  The plugin will automatically activate when a `:credo` dependency is detected in `mix.exs`.

  ## Options

  * `:strict?` - Whether to run Credo in strict mode (default: `false`)
  """

  @behaviour Claude.Plugin

  @impl Claude.Plugin
  def config(opts) do
    igniter = Keyword.get(opts, :igniter)
    strict? = Keyword.get(opts, :strict?, false)

    if detect_credo_project?(igniter) do
      strict_flag = if strict?, do: " --strict", else: ""
      credo_command = "credo#{strict_flag} {{tool_input.file_path}}"

      %{
        hooks: %{
          post_tool_use: [
            {credo_command, when: [:write, :edit, :multi_edit]}
          ],
          pre_tool_use: [
            {credo_command, when: "Bash", command: ~r/^git commit/}
          ]
        }
      }
    else
      %{}
    end
  end

  defp detect_credo_project?(igniter) do
    Igniter.Project.Deps.has_dep?(igniter, :credo)
  end
end
