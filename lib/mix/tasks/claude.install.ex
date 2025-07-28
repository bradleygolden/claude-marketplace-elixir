defmodule Mix.Tasks.Claude.Install do
  @shortdoc "Setup Claude for your Elixir project"

  @moduledoc """
  Setup Claude for your Elixir project.

  This task is automatically run when you execute:

      mix igniter.install claude

  It sets up Claude Code integration for your Elixir project by:

  1. Creating a .claude.exs configuration file for project-specific settings
  2. Installing all Claude hooks for auto-formatting and compilation checking
  3. Adding usage_rules dependency for better LLM integration
  4. Syncing usage rules to CLAUDE.md for enhanced code assistance
  5. Generating any configured subagents for specialized assistance
  6. Ensuring your project is properly configured for Claude Code integration

  ## Example

  ```sh
  mix igniter.install claude
  ```
  """

  use Igniter.Mix.Task

  alias Claude.Core.ConfigTemplate
  alias Claude.Core.Project

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix igniter.install claude",
      only: [:dev],
      dep_opts: [runtime: false]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    claude_exs_path = Path.join(Project.root(), ".claude.exs")
    relative_exs_path = Path.relative_to_cwd(claude_exs_path)

    igniter =
      if File.exists?(claude_exs_path) do
        igniter
        |> Igniter.add_notice("""
        Claude configuration file already exists at #{relative_exs_path}
        Skipping file creation to preserve your existing configuration.
        """)
      else
        igniter
        |> Igniter.create_new_file(relative_exs_path, ConfigTemplate.claude_exs_content())
        |> Igniter.add_notice("""
        Claude has been configured for your project!

        Configuration file created at #{relative_exs_path}
        You can customize Claude's behavior by editing this file.
        """)
      end

    igniter
    |> Igniter.Project.Deps.add_dep({:usage_rules, "~> 0.1", only: [:dev]}, on_exists: :skip)
    |> Igniter.compose_task("claude.hooks.install", [])
    |> Igniter.compose_task("claude.mcp.sync", [])
    |> Igniter.compose_task("claude.usage_rules.sync", [])
    |> Igniter.compose_task("claude.subagents.generate", [])
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false
end
