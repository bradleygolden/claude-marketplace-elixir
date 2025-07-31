defmodule Claude.MCP.Config do
  @moduledoc """
  Manages MCP server configuration in .mcp.json files.

  MCP servers should be configured in .mcp.json at the project root,
  not in settings.json. This module handles reading and writing
  MCP configurations according to Claude Code standards.
  """

  @doc """
  Writes MCP server configuration to .mcp.json file.
  """
  def write_mcp_config(igniter, servers) when is_list(servers) do
    mcp_config = build_mcp_config(servers)

    case mcp_config do
      %{"mcpServers" => servers_map} when map_size(servers_map) > 0 ->
        igniter
        |> Igniter.create_or_update_file(
          ".mcp.json",
          Jason.encode!(mcp_config, pretty: true) <> "\n",
          fn source ->
            update_existing_mcp_config(source, servers)
          end
        )

      _ ->
        igniter
    end
  end

  @doc """
  Removes MCP server configuration from .mcp.json file.
  """
  def remove_mcp_server(igniter, server_name) when is_atom(server_name) do
    remove_mcp_server(igniter, Atom.to_string(server_name))
  end

  def remove_mcp_server(igniter, server_name) when is_binary(server_name) do
    if Igniter.exists?(igniter, ".mcp.json") do
      igniter
      |> Igniter.update_file(".mcp.json", fn source ->
        content = Rewrite.Source.get(source, :content)

        case Jason.decode(content) do
          {:ok, %{"mcpServers" => servers} = config} ->
            updated_servers = Map.delete(servers, server_name)

            updated_config =
              if map_size(updated_servers) == 0 do
                %{"mcpServers" => %{}}
              else
                Map.put(config, "mcpServers", updated_servers)
              end

            new_content = Jason.encode!(updated_config, pretty: true) <> "\n"
            Rewrite.Source.update(source, :content, new_content)

          _ ->
            source
        end
      end)
    else
      igniter
    end
  end

  defp build_mcp_config(servers) do
    mcp_servers =
      servers
      |> Enum.reduce(%{}, fn server, acc ->
        case server do
          :tidewave ->
            Map.put(acc, "tidewave", tidewave_config(4000))

          {:tidewave, opts} ->
            if Keyword.get(opts, :enabled?, true) do
              port = Keyword.get(opts, :port, 4000)
              Map.put(acc, "tidewave", tidewave_config(port))
            else
              acc
            end

          {name, opts} when is_atom(name) ->
            if Keyword.get(opts, :enabled?, true) do
              Map.put(acc, Atom.to_string(name), build_server_config(name, opts))
            else
              acc
            end

          name when is_atom(name) ->
            Map.put(acc, Atom.to_string(name), build_server_config(name, []))
        end
      end)

    %{"mcpServers" => mcp_servers}
  end

  defp update_existing_mcp_config(source, servers) do
    content = Rewrite.Source.get(source, :content)

    case Jason.decode(content) do
      {:ok, existing_config} ->
        new_config = build_mcp_config(servers)

        merged_servers =
          existing_config
          |> Map.get("mcpServers", %{})
          |> Map.merge(new_config["mcpServers"])

        updated_config = Map.put(existing_config, "mcpServers", merged_servers)
        new_content = Jason.encode!(updated_config, pretty: true) <> "\n"
        Rewrite.Source.update(source, :content, new_content)

      {:error, _} ->
        new_config = build_mcp_config(servers)
        new_content = Jason.encode!(new_config, pretty: true) <> "\n"
        Rewrite.Source.update(source, :content, new_content)
    end
  end

  defp tidewave_config(port) do
    %{
      "type" => "sse",
      "url" => "http://localhost:#{port}/tidewave/mcp"
    }
  end

  defp build_server_config(name, opts) do
    case name do
      :tidewave ->
        port = Keyword.get(opts, :port, 4000)
        tidewave_config(port)

      _ ->
        %{
          "command" => Atom.to_string(name),
          "args" => [],
          "env" => %{}
        }
    end
  end
end
