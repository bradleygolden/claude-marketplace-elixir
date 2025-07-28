defmodule Mix.Tasks.Claude.Install.Tidewave do
  @shortdoc "Install and configure Tidewave MCP server"

  @moduledoc """
  Installs and configures Tidewave as an MCP server for your Phoenix project.

  This task:
  1. Adds :tidewave to your .claude.exs mcp_servers list
  2. Syncs the configuration to Claude settings
  3. Provides instructions for adding Tidewave to your Phoenix application

  ## Usage

      mix claude.install.tidewave

  ## What is Tidewave?

  Tidewave is an Elixir library that integrates with Phoenix applications
  to provide MCP (Model Context Protocol) support. It exposes development
  tools and database access through a Server-Sent Events (SSE) endpoint,
  allowing Claude to interact with your running Phoenix application.

  ## Requirements

  - A Phoenix application
  - Tidewave added as a dependency to your project
  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix claude.install.tidewave",
      only: [:dev]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> check_phoenix_project()
    |> add_tidewave_to_config()
    |> Igniter.compose_task("claude.mcp.sync", [])
    |> add_tidewave_dependency_notice()
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false

  # Private functions

  defp check_phoenix_project(igniter) do
    cond do
      # Check if Phoenix is in the project dependencies
      Claude.Core.Deps.phoenix_dep?() ->
        igniter

      # Check if this might be a Phoenix project by looking for common files
      File.exists?("lib/#{app_name()}_web.ex") or File.exists?("lib/#{app_name()}_web/router.ex") ->
        igniter
        |> Igniter.add_notice(
          "This appears to be a Phoenix project. Tidewave will be configured."
        )

      true ->
        igniter
        |> Igniter.add_warning("""
        This doesn't appear to be a Phoenix project.

        Tidewave is designed to work with Phoenix applications.
        If this is a Phoenix project, you can ignore this warning.
        """)
    end
  end

  defp app_name do
    Mix.Project.config()[:app] |> to_string()
  end

  defp add_tidewave_to_config(igniter) do
    # Use the claude.mcp.add task to add tidewave
    Igniter.compose_task(igniter, "claude.mcp.add", ["tidewave"])
  end

  defp add_tidewave_dependency_notice(igniter) do
    # Check if tidewave is already in deps
    tidewave_in_deps = tidewave_dep?()

    dependency_instructions =
      if tidewave_in_deps do
        "✓ Tidewave is already in your project dependencies"
      else
        """
        To add Tidewave to your Phoenix project:

        1. Add to your deps in mix.exs:
           
           def deps do
             [
               ...,
               {:tidewave, "~> 0.2.0"}
             ]
           end

        2. Run: mix deps.get

        3. Configure Tidewave in config/dev.exs (see Tidewave docs)
        """
      end

    port_info = """
    The MCP endpoint will be available at:
      http://localhost:4000/tidewave/mcp

    If your Phoenix app runs on a different port, set:
      export PHOENIX_PORT=your_port_number
    """

    igniter
    |> Igniter.add_notice("""
    Tidewave MCP server has been configured for your project!

    #{dependency_instructions}

    To use Tidewave:
      1. Ensure Tidewave is added to your Phoenix project (see above)
      2. Start your Phoenix server: mix phx.server
      3. Claude will connect to the MCP endpoint automatically

    #{port_info}

    For more information, see: https://hexdocs.pm/tidewave
    """)
  end

  defp tidewave_dep? do
    Claude.Core.Deps.tidewave_dep?()
  end
end
