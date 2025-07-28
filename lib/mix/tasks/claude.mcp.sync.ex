defmodule Mix.Tasks.Claude.Mcp.Sync do
  @shortdoc "Sync MCP servers from .claude.exs to settings.json"

  @moduledoc """
  Syncs MCP server configuration from your project's `.claude.exs` file
  to Claude's `.claude/settings.json` file.

  This task reads the `mcp_servers` list from `.claude.exs`, resolves
  their configurations from the catalog, and updates the Claude settings.

  ## What it does

  - Reads MCP server configuration from `.claude.exs`
  - Validates that all servers exist in the catalog
  - Syncs the configuration to `.claude/settings.json`
  - Provides setup instructions for each server

  ## Usage

      mix claude.mcp.sync

  This task is automatically run as part of `mix claude.install`.
  """

  use Igniter.Mix.Task

  alias Claude.Core.Project
  alias Claude.MCP.{Registry, Catalog}

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix claude.mcp.sync",
      only: [:dev]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    settings_path = Path.join(Project.claude_path(), "settings.json")
    relative_settings_path = Path.relative_to_cwd(settings_path)

    # Validate MCP servers first
    case Registry.validate() do
      {:ok, servers} ->
        if Enum.empty?(servers) do
          igniter
        else
          igniter
          |> sync_mcp_servers(relative_settings_path)
          |> add_sync_notice(servers, relative_settings_path)
        end

      {:error, invalid_servers} ->
        igniter
        |> Igniter.add_issue("""
        Invalid MCP servers in .claude.exs: #{inspect(invalid_servers)}

        Available servers: #{inspect(Catalog.available())}
        """)
    end
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false

  # Private functions

  defp sync_mcp_servers(igniter, relative_settings_path) do
    initial_settings = %{}
    initial_content = Jason.encode!(initial_settings, pretty: true) <> "\n"

    igniter
    |> Igniter.create_or_update_file(relative_settings_path, initial_content, fn source ->
      content = Rewrite.Source.get(source, :content)

      new_content =
        case Jason.decode(content) do
          {:ok, settings} ->
            mcp_configs = Registry.all()

            updated_settings =
              if map_size(mcp_configs) == 0 do
                Map.delete(settings, "mcpServers")
              else
                Map.put(settings, "mcpServers", mcp_configs)
              end

            Jason.encode!(updated_settings, pretty: true) <> "\n"

          {:error, _} ->
            # If we can't parse existing settings, create new ones
            mcp_configs = Registry.all()
            settings = %{"mcpServers" => mcp_configs}
            Jason.encode!(settings, pretty: true) <> "\n"
        end

      Rewrite.Source.update(source, :content, new_content)
    end)
  end

  defp add_sync_notice(igniter, servers, relative_settings_path) do
    server_info =
      servers
      |> Enum.map(fn server ->
        config = Catalog.get(server)
        "  - #{server}: #{config.description}"
      end)
      |> Enum.join("\n")

    setup_instructions =
      servers
      |> Enum.filter(fn server ->
        case Catalog.get(server) do
          %{setup_instructions: instructions} when not is_nil(instructions) -> true
          _ -> false
        end
      end)
      |> Enum.map(fn server ->
        instructions = Catalog.setup_instructions(server)
        "\n#{server}:\n#{instructions}"
      end)
      |> Enum.join("\n")

    notice = """
    MCP servers have been synced to #{relative_settings_path}

    Configured servers:
    #{server_info}
    """

    notice =
      if setup_instructions != "" do
        notice <> "\n\nSetup instructions:\n" <> setup_instructions
      else
        notice
      end

    Igniter.add_notice(igniter, notice)
  end
end
