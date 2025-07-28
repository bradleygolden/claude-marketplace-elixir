defmodule Claude.CLI.Hooks.Install do
  @moduledoc """
  Handles the installation of Claude Code hooks.
  """

  alias Claude.Hooks
  alias Claude.Core.Project
  alias Claude.Utils.Shell

  def run(_args) do
    project_path = Project.claude_path()

    Shell.info("Installing Claude hooks to #{project_path}")

    case Hooks.install() do
      {:ok, message} ->
        Shell.success(message)
        Shell.blank()
        Shell.info("Enabled hooks:")

        Hooks.all_hooks()
        |> Enum.each(fn {hook_module, _config} ->
          Shell.bullet(hook_module.description())
        end)

        :ok

      {:error, reason} ->
        Shell.error(reason)
        {:error, reason}
    end
  end
end
