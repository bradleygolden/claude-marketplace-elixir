defmodule Claude.MCP.Installer do
  @moduledoc """
  Installs MCP servers from .claude.exs to Claude settings.json.

  This module handles the synchronization of MCP server configurations
  from the project's .claude.exs file to Claude's settings.json.
  """

  alias Claude.Core.Settings
  alias Claude.MCP.Registry
  require Logger

  @doc """
  Install all configured MCP servers to settings.json.

  This reads the mcp_servers list from .claude.exs, resolves their
  configurations from the catalog, and updates the Claude settings.

  ## Examples

      iex> Claude.MCP.Installer.install_all()
      {:ok, ["tidewave", "postgres"]}
  """
  @spec install_all() :: {:ok, [String.t()]} | {:error, term()}
  def install_all do
    case Registry.validate() do
      {:ok, _servers} ->
        server_configs = Registry.all()

        case update_settings(server_configs) do
          :ok ->
            installed_names = Map.keys(server_configs)
            log_installation_success(installed_names)
            {:ok, installed_names}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, invalid_servers} ->
        {:error, "Invalid MCP servers in .claude.exs: #{inspect(invalid_servers)}"}
    end
  end

  @doc """
  Remove all MCP servers from settings.json.

  This clears the mcpServers configuration from Claude settings.
  """
  @spec uninstall_all() :: :ok | {:error, term()}
  def uninstall_all do
    Settings.update(fn settings ->
      Map.delete(settings, "mcpServers")
    end)
  end

  @doc """
  Check if MCP servers are currently installed in settings.json.
  """
  @spec installed?() :: boolean()
  def installed? do
    case Settings.read() do
      {:ok, settings} ->
        mcp_servers = Map.get(settings, "mcpServers", %{})
        map_size(mcp_servers) > 0

      {:error, _} ->
        false
    end
  end

  @doc """
  Get currently installed MCP servers from settings.json.
  """
  @spec installed_servers() :: %{String.t() => map()}
  def installed_servers do
    case Settings.read() do
      {:ok, settings} ->
        Map.get(settings, "mcpServers", %{})

      {:error, _} ->
        %{}
    end
  end

  @doc """
  Check if installation is needed by comparing .claude.exs with settings.json.
  """
  @spec needs_sync?() :: boolean()
  def needs_sync? do
    configured = Registry.all()
    installed = installed_servers()

    configured != installed
  end

  # Private functions

  defp update_settings(server_configs) do
    Settings.update(fn settings ->
      if map_size(server_configs) == 0 do
        # Remove mcpServers if no servers configured
        Map.delete(settings, "mcpServers")
      else
        Map.put(settings, "mcpServers", server_configs)
      end
    end)
  end

  defp log_installation_success([]), do: :ok

  defp log_installation_success(server_names) do
    Logger.info("Installed MCP servers: #{Enum.join(server_names, ", ")}")
  end
end
