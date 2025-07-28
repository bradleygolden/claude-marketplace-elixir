defmodule Mix.Tasks.Claude.Mcp.List do
  use Mix.Task

  @shortdoc "Show MCP server configuration status"

  @moduledoc """
  Shows the MCP server configuration status for your project.

  Currently, Claude supports Tidewave integration for Phoenix projects,
  which is automatically configured when Phoenix is detected.

  ## Usage

      mix claude.mcp.list
  """

  alias Claude.MCP.Registry

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:claude)

    configured_servers = Registry.configured_servers()
    is_phoenix = Claude.Core.Deps.phoenix_project?()
    tidewave_configured = :tidewave in configured_servers

    Mix.shell().info("\nMCP Server Status")
    Mix.shell().info("=================\n")

    if is_phoenix do
      status = if tidewave_configured, do: "✓", else: "○"
      Mix.shell().info("#{status} Tidewave (Phoenix integration)")

      if tidewave_configured do
        Mix.shell().info("  Status: Configured")
        
        # Get the actual endpoint from settings
        endpoint = 
          case Claude.MCP.Installer.installed_servers() do
            %{"tidewave" => %{"url" => url}} -> url
            _ -> "http://localhost:4000/tidewave/mcp"
          end
        
        Mix.shell().info("  Endpoint: #{endpoint}")
        Mix.shell().info("")

        if Claude.Core.Deps.tidewave_available?() do
          Mix.shell().info("  ✓ Tidewave dependency is available")
        else
          Mix.shell().info("""

          To complete setup:
          1. Add {:tidewave, "~> 0.2.0"} to your deps
          2. Run mix deps.get
          3. Configure in config/dev.exs
          """)
        end
      else
        Mix.shell().info("""

        Tidewave can be configured for your Phoenix project.

        Run:
          mix claude.install

        Or manually:
          mix claude.mcp.add tidewave
        """)
      end
    else
      Mix.shell().info("No MCP servers available for non-Phoenix projects.\n")

      if tidewave_configured do
        Mix.shell().info("Note: Tidewave is configured but requires Phoenix.")
      end
    end
  end
end
