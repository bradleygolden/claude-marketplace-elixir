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
        config
        |> Map.get(:mcp_servers, [])
        |> Enum.map(fn
          atom when is_atom(atom) -> atom
          {server, _opts} when is_atom(server) -> server
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)

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
    add_server(server_name, [])
  end

  @doc """
  Add a server with custom configuration.

  ## Examples

      iex> Claude.MCP.Registry.add_server(:tidewave, port: 5000)
      :ok
  """
  @spec add_server(atom(), keyword()) :: :ok | {:error, term()}
  def add_server(server_name, opts) when is_atom(server_name) and is_list(opts) do
    unless Catalog.exists?(server_name) do
      {:error, "Unknown MCP server: #{server_name}"}
    else
      case ClaudeExs.read() do
        {:ok, config} ->
          servers = Map.get(config, :mcp_servers, [])
          configured_names = configured_servers()

          if server_name in configured_names do
            {:error, "Server #{server_name} is already configured"}
          else
            # Build the server entry based on options
            server_entry =
              cond do
                # Always use explicit port for tidewave
                server_name == :tidewave and opts == [] ->
                  {:tidewave, [port: 4000]}

                Keyword.keyword?(opts) and opts != [] ->
                  {server_name, opts}

                true ->
                  server_name
              end

            updated_config = Map.put(config, :mcp_servers, servers ++ [server_entry])
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

        updated_servers =
          Enum.reject(servers, fn
            atom when is_atom(atom) -> atom == server_name
            {server, _opts} when is_atom(server) -> server == server_name
            _ -> false
          end)

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
    case ClaudeExs.read() do
      {:ok, config} ->
        servers = Map.get(config, :mcp_servers, [])

        {valid, invalid} =
          Enum.split_with(servers, fn
            atom when is_atom(atom) -> Catalog.exists?(atom)
            {server, _opts} when is_atom(server) -> Catalog.exists?(server)
            _ -> false
          end)

        invalid_names =
          Enum.map(invalid, fn
            atom when is_atom(atom) -> atom
            {server, _opts} when is_atom(server) -> server
            other -> inspect(other)
          end)

        if Enum.empty?(invalid) do
          {:ok, valid}
        else
          {:error, invalid_names}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private functions

  defp build_server_configs(servers) when is_list(servers) do
    servers
    |> Enum.reduce(%{}, fn
      server_name, acc when is_atom(server_name) ->
        case Catalog.to_settings_json(server_name) do
          nil -> acc
          config -> Map.put(acc, to_string(server_name), config)
        end

      {server_name, opts}, acc when is_atom(server_name) and is_list(opts) ->
        # Skip disabled servers
        if Keyword.get(opts, :enabled?, true) == false do
          acc
        else
          case Catalog.to_settings_json(server_name) do
            nil ->
              acc

            base_config ->
              # Apply custom configuration over base config
              config = apply_custom_config(base_config, opts)
              Map.put(acc, to_string(server_name), config)
          end
        end

      _, acc ->
        acc
    end)
  end

  defp build_server_configs(_), do: %{}

  defp apply_custom_config(base_config, opts) when is_list(opts) do
    # Apply custom port if specified
    case Keyword.get(opts, :port) do
      nil ->
        base_config

      port ->
        # Update the URL with the custom port
        case base_config["url"] do
          nil ->
            base_config

          url ->
            # Parse and update the URL with the new port
            updated_url = update_url_port(url, port)
            Map.put(base_config, "url", updated_url)
        end
    end
  end

  defp update_url_port(url, port) do
    case URI.parse(url) do
      %URI{} = uri ->
        uri
        |> Map.put(:port, port)
        |> URI.to_string()

      _ ->
        url
    end
  end
end
