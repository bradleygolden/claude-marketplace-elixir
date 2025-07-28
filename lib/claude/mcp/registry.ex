defmodule Claude.MCP.Registry do
  @moduledoc """
  Registry for discovering and managing MCP servers from .claude.exs configuration.

  Reads the mcp_servers list from .claude.exs and resolves them against
  the Claude.MCP.Catalog for their full configuration.
  """

  alias Claude.Core.ClaudeExs
  alias Claude.MCP.Catalog

  @doc """
  Get all configured MCP servers.

  Returns a map of server name to configuration suitable for
  Claude settings.json.

  ## Examples

      iex> Claude.MCP.Registry.all()
      %{
        "tidewave" => %{
          "type" => "sse",
          "url" => "http://localhost:3000/mcp/sse",
          "description" => "Tidewave development server"
        }
      }
  """
  @spec all() :: %{String.t() => map()}
  def all do
    case ClaudeExs.read() do
      {:ok, config} ->
        servers = Map.get(config, :mcp_servers, [])
        build_server_configs(servers)

      {:error, _} ->
        %{}
    end
  end

  @doc """
  Get configured server names from .claude.exs.

  ## Examples

      iex> Claude.MCP.Registry.configured_servers()
      [:tidewave, :postgres]
  """
  @spec configured_servers() :: [atom()]
  def configured_servers do
    case ClaudeExs.read() do
      {:ok, config} ->
        Map.get(config, :mcp_servers, [])

      {:error, _} ->
        []
    end
  end

  @doc """
  Check if a server is configured.

  ## Examples

      iex> Claude.MCP.Registry.configured?(:tidewave)
      true
  """
  @spec configured?(atom()) :: boolean()
  def configured?(server_name) when is_atom(server_name) do
    server_name in configured_servers()
  end

  @doc """
  Add a server to the configuration.

  ## Examples

      iex> Claude.MCP.Registry.add_server(:postgres)
      :ok
  """
  @spec add_server(atom()) :: :ok | {:error, term()}
  def add_server(server_name) when is_atom(server_name) do
    unless Catalog.exists?(server_name) do
      {:error, "Unknown MCP server: #{server_name}"}
    else
      case ClaudeExs.read() do
        {:ok, config} ->
          servers = Map.get(config, :mcp_servers, [])

          if server_name in servers do
            {:error, "Server #{server_name} is already configured"}
          else
            updated_config = Map.put(config, :mcp_servers, servers ++ [server_name])
            ClaudeExs.write(updated_config)
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Remove a server from the configuration.

  ## Examples

      iex> Claude.MCP.Registry.remove_server(:postgres)
      :ok
  """
  @spec remove_server(atom()) :: :ok | {:error, term()}
  def remove_server(server_name) when is_atom(server_name) do
    case ClaudeExs.read() do
      {:ok, config} ->
        servers = Map.get(config, :mcp_servers, [])
        updated_servers = Enum.reject(servers, &(&1 == server_name))

        if servers == updated_servers do
          {:error, "Server #{server_name} is not configured"}
        else
          updated_config = Map.put(config, :mcp_servers, updated_servers)
          ClaudeExs.write(updated_config)
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Validate all configured servers exist in the catalog.

  Returns {:ok, servers} or {:error, invalid_servers}.
  """
  @spec validate() :: {:ok, [atom()]} | {:error, [atom()]}
  def validate do
    servers = configured_servers()
    invalid = Enum.reject(servers, &Catalog.exists?/1)

    if Enum.empty?(invalid) do
      {:ok, servers}
    else
      {:error, invalid}
    end
  end

  # Private functions

  defp build_server_configs(servers) when is_list(servers) do
    servers
    |> Enum.filter(&is_atom/1)
    |> Enum.reduce(%{}, fn server_name, acc ->
      case Catalog.to_settings_json(server_name) do
        nil -> acc
        config -> Map.put(acc, to_string(server_name), config)
      end
    end)
  end

  defp build_server_configs(_), do: %{}
end
