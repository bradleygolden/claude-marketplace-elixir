defmodule Claude.Core.Deps do
  @moduledoc """
  Helper functions for checking available modules and dependencies.

  This module checks for compiled modules rather than mix.exs dependencies,
  allowing for optional dependencies and runtime detection.
  """

  @doc """
  Check if Phoenix is available in the current project.

  Returns true if the Phoenix module can be loaded, indicating Phoenix
  is available either as a direct or transitive dependency.
  """
  @spec phoenix_available?() :: boolean()
  def phoenix_available? do
    Code.ensure_loaded?(Phoenix)
  end

  @doc """
  Check if Tidewave is available in the current project.

  Returns true if the Tidewave module can be loaded.
  """
  @spec tidewave_available?() :: boolean()
  def tidewave_available? do
    Code.ensure_loaded?(Tidewave)
  end

  @doc """
  Check if this appears to be a Phoenix project by looking for Phoenix
  modules or Phoenix-specific files.

  This is useful during compile time when modules might not be loaded yet.
  """
  @spec phoenix_project?() :: boolean()
  def phoenix_project? do
    # First try runtime check
    # Then check for Phoenix-specific files as fallback
    phoenix_available?() ||
      phoenix_files_exist?()
  end

  defp phoenix_files_exist? do
    app_name = to_string(Mix.Project.config()[:app] || "")

    # Phoenix 1.6+ structure
    File.exists?("lib/#{app_name}_web.ex") ||
      File.exists?("lib/#{app_name}_web/endpoint.ex") ||
      File.exists?("lib/#{app_name}_web/router.ex") ||
      File.exists?("assets/js/app.js")
  end

  # Deprecated functions that forward to new names for compatibility
  @deprecated "Use phoenix_available?/0 instead"
  def phoenix_dep?, do: phoenix_available?()

  @deprecated "Use tidewave_available?/0 instead"
  def tidewave_dep?, do: tidewave_available?()
end
