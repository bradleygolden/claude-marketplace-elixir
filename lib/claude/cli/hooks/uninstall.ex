defmodule Claude.CLI.Hooks.Uninstall do
  @moduledoc """
  Handles the uninstallation of Claude Code hooks.
  """

  alias Claude.Hooks
  alias Claude.Utils.Shell

  def run(_args) do
    case Hooks.uninstall() do
      {:ok, message} ->
        Shell.success(message)
        :ok

      {:error, reason} ->
        Shell.error(reason)
        {:error, reason}
    end
  end
end
