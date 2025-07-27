defmodule Mix.Tasks.Claude.Hooks.Install do
  @shortdoc "Install Claude hooks to your project"

  @moduledoc """
  Installs Claude hooks to your project's `.claude/settings.json` file.

  This task uses Igniter to safely modify your project's settings,
  ensuring that Claude Code integration works seamlessly with your
  Elixir development workflow.

  ## What it does

  Installs all available Claude hooks including:
  - Auto-formatting for Elixir files after edits
  - Compilation checking to catch errors immediately
  - Pre-commit validation for formatting, compilation, and dependencies

  ## Usage

      mix claude.hooks.install

  This task can be composed with other Igniter tasks for a seamless
  installation experience.
  """

  use Igniter.Mix.Task

  alias Claude.Core.Project
  alias Claude.Hooks.Installer

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix claude.hooks.install",
      only: [:dev]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    settings_path = Path.join(Project.claude_path(), "settings.json")
    relative_settings_path = Path.relative_to_cwd(settings_path)

    initial_settings = Installer.install_hooks(%{})
    initial_content = Jason.encode!(initial_settings, pretty: true) <> "\n"

    igniter
    |> Igniter.create_or_update_file(relative_settings_path, initial_content, fn source ->
      content = Rewrite.Source.get(source, :content)

      new_content =
        case Jason.decode(content) do
          {:ok, settings} ->
            updated_settings = Installer.install_hooks(settings)
            Jason.encode!(updated_settings, pretty: true) <> "\n"

          {:error, _} ->
            initial_content
        end

      Rewrite.Source.update(source, :content, new_content)
    end)
    |> Igniter.add_notice("""
    Claude hooks have been installed to #{relative_settings_path}

    Enabled hooks:
    #{Installer.format_hooks_list()}
    """)
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false
end
