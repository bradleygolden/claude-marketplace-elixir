defmodule Claude.Plugins.Ash do
  @moduledoc """
  Ash plugin for Claude Code providing support for Ash Framework projects.

  This plugin automatically configures Claude Code for Ash projects by:

  * **Hooks**: Runs `ash.codegen --check` after file modifications to ensure generated code is up to date
  * **Nested Memories**: Applies Ash usage rules to the `lib/<app_name>` directory for domain/resource code
  * **Smart Detection**: Automatically activates when the `:ash` dependency is detected in `mix.exs`

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.Ash]
      }

  Or with options:

      %{
        plugins: [{Claude.Plugins.Ash, []}]
      }

  The plugin will automatically activate when an `:ash` dependency is detected in `mix.exs`.

  ## Configuration Generated

  * `post_tool_use` hook: Runs `ash.codegen --check` after write/edit operations to validate generated code
  * `nested_memories`: Applies Ash usage rules to `lib/<app_name>` directory for context-aware assistance
  """

  @behaviour Claude.Plugin

  def config(opts) do
    igniter = Keyword.get(opts, :igniter)

    if detect_ash_project?(igniter) do
      app_name = get_app_name(igniter)

      %{
        hooks: %{
          post_tool_use: [
            {"ash.codegen --check", when: [:write, :edit, :multi_edit]}
          ]
        },
        nested_memories: %{
          "lib/#{app_name}" => ["ash"]
        }
      }
    else
      %{}
    end
  end

  defp detect_ash_project?(igniter) do
    Igniter.Project.Deps.has_dep?(igniter, :ash)
  end

  defp get_app_name(igniter) do
    igniter
    |> Igniter.Project.Module.module_name_prefix()
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end
end
