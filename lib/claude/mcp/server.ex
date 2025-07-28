defmodule Claude.MCP.Server do
  @moduledoc """
  Represents an MCP server configuration.

  MCP servers can be configured in `.claude.exs` and are automatically
  installed to the Claude settings when `mix claude.install` is run.
  """

  @type server_type :: :stdio | :sse | :http

  @type t :: %__MODULE__{
          name: String.t(),
          type: server_type(),
          command: String.t() | nil,
          args: list(String.t()),
          url: String.t() | nil,
          headers: map() | nil,
          env: map(),
          default: boolean(),
          description: String.t() | nil
        }

  defstruct [
    :name,
    :type,
    :command,
    :args,
    :url,
    :headers,
    :env,
    :default,
    :description
  ]

  @doc """
  Creates a new MCP server configuration from a map.
  """
  def new(config) when is_map(config) do
    %__MODULE__{
      name: Map.fetch!(config, :name),
      type: Map.fetch!(config, :type),
      command: Map.get(config, :command),
      args: Map.get(config, :args, []),
      url: Map.get(config, :url),
      headers: Map.get(config, :headers),
      env: Map.get(config, :env, %{}),
      default: Map.get(config, :default, false),
      description: Map.get(config, :description)
    }
    |> validate!()
  end

  @doc """
  Validates a server configuration.
  """
  def validate!(%__MODULE__{} = server) do
    validate_type!(server)
    validate_transport!(server)
    server
  end

  defp validate_type!(%{type: type}) when type not in [:stdio, :sse, :http] do
    raise ArgumentError, "Invalid server type: #{inspect(type)}. Must be :stdio, :sse, or :http"
  end

  defp validate_type!(_), do: :ok

  defp validate_transport!(%{type: :stdio, command: nil}) do
    raise ArgumentError, "stdio servers require a command"
  end

  defp validate_transport!(%{type: type, url: nil}) when type in [:sse, :http] do
    raise ArgumentError, "#{type} servers require a url"
  end

  defp validate_transport!(%{type: :stdio, url: url}) when not is_nil(url) do
    raise ArgumentError, "stdio servers cannot have a url"
  end

  defp validate_transport!(%{type: type, command: cmd})
       when type in [:sse, :http] and not is_nil(cmd) do
    raise ArgumentError, "#{type} servers cannot have a command"
  end

  defp validate_transport!(_), do: :ok

  @doc """
  Converts the server to Claude settings JSON format.
  """
  def to_settings_json(%__MODULE__{type: :stdio} = server) do
    %{
      "command" => server.command,
      "args" => server.args,
      "env" => server.env
    }
    |> maybe_add_description(server.description)
  end

  def to_settings_json(%__MODULE__{type: type} = server) when type in [:sse, :http] do
    %{
      "type" => to_string(type),
      "url" => server.url
    }
    |> maybe_add_headers(server.headers)
    |> maybe_add_env(server.env)
    |> maybe_add_description(server.description)
  end

  defp maybe_add_description(map, nil), do: map
  defp maybe_add_description(map, description), do: Map.put(map, "description", description)

  defp maybe_add_headers(map, nil), do: map
  defp maybe_add_headers(map, headers) when headers == %{}, do: map
  defp maybe_add_headers(map, headers), do: Map.put(map, "headers", headers)

  defp maybe_add_env(map, nil), do: map
  defp maybe_add_env(map, env) when env == %{}, do: map
  defp maybe_add_env(map, env), do: Map.put(map, "env", env)
end
