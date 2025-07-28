defmodule Mix.Tasks.Claude.Mcp.List do
  use Mix.Task
  
  @shortdoc "List available and configured MCP servers"

  @moduledoc """
  Lists all available MCP servers from the catalog and shows which ones
  are currently configured in your project.

  ## Usage

      mix claude.mcp.list

  This will display:
  - All available servers from the catalog
  - Which servers are currently configured in .claude.exs
  - A brief description of each server
  """

  alias Claude.MCP.{Catalog, Registry}

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:claude)

    configured_servers = Registry.configured_servers()
    available_servers = Catalog.available()

    Mix.shell().info("\nAvailable MCP servers:")
    Mix.shell().info("======================\n")

    Enum.each(available_servers, fn server ->
      config = Catalog.get(server)
      configured? = server in configured_servers

      status = if configured?, do: " ✓", else: "  "
      type = format_type(config.type)

      Mix.shell().info("#{status} #{server} (#{type})")
      Mix.shell().info("   #{config.description}")
      Mix.shell().info("")
    end)

    if Enum.empty?(configured_servers) do
      Mix.shell().info("""
      No MCP servers are currently configured.

      To add a server, run:
        mix claude.mcp.add SERVER_NAME

      Example:
        mix claude.mcp.add tidewave
      """)
    else
      Mix.shell().info("""
      Currently configured servers: #{Enum.join(configured_servers, ", ")}

      To sync servers to Claude settings, run:
        mix claude.mcp.sync
      """)
    end
  end

  defp format_type(:stdio), do: "stdio"
  defp format_type(:sse), do: "SSE"
  defp format_type(:http), do: "HTTP"
end
