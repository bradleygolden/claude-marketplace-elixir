defmodule Mix.Tasks.Claude.Mcp.Add do
  @shortdoc "Add an MCP server to your project"

  @moduledoc """
  Adds an MCP server to your project's `.claude.exs` configuration.

  This task adds a pre-configured MCP server from the catalog to your
  project and automatically syncs it to Claude's settings.

  ## Usage

      mix claude.mcp.add SERVER_NAME

  Where SERVER_NAME is one of the available servers in the catalog.

  ## Examples

      mix claude.mcp.add tidewave

  This will add the server configuration to your `.claude.exs` file.
  For Tidewave, it includes a default port that you can modify directly
  in the configuration file.

  ## Available Servers

  Run `mix claude.mcp.list` to see all available servers.
  """

  use Igniter.Mix.Task

  alias Claude.Core.Project
  alias Claude.MCP.{Catalog, Registry}

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix claude.mcp.add tidewave",
      only: [:dev]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    case igniter.args.positional do
      [server_name | _] ->
        server_atom = String.to_atom(server_name)

        cond do
          not Catalog.exists?(server_atom) ->
            available = Catalog.available() |> Enum.map(&to_string/1) |> Enum.join(", ")

            igniter
            |> Igniter.add_issue("""
            Unknown MCP server: #{server_name}

            Available servers: #{available}

            Run `mix claude.mcp.list` for more details about each server.
            """)

          Registry.configured?(server_atom) ->
            igniter
            |> Igniter.add_notice("MCP server '#{server_name}' is already configured.")

          true ->
            claude_exs_path = Path.join(Project.root(), ".claude.exs")
            relative_exs_path = Path.relative_to_cwd(claude_exs_path)

            server_config = build_server_config(server_atom)

            igniter
            |> update_claude_exs(relative_exs_path, server_config)
            |> Igniter.compose_task("claude.mcp.sync", [])
            |> add_setup_notice(server_atom)
        end

      _ ->
        igniter
        |> Igniter.add_issue("""
        Please specify a server name.

        Usage: mix claude.mcp.add SERVER_NAME

        Run `mix claude.mcp.list` to see available servers.
        """)
    end
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false

  # Private functions

  defp build_server_config(:tidewave) do
    # Always write tidewave with explicit port so users can see they can change it
    {:tidewave, [port: 4000]}
  end

  defp build_server_config(server_atom), do: server_atom

  defp update_claude_exs(igniter, relative_path, server_config) do
    # Create default content if file doesn't exist
    default_content = """
    %{
      mcp_servers: [#{inspect(server_config)}]
    }
    """

    igniter
    |> Igniter.create_or_update_file(relative_path, default_content, fn source ->
      content = Rewrite.Source.get(source, :content)

      # Parse the existing content
      case Code.string_to_quoted(content) do
        {:ok, ast} ->
          # Update the AST to add the server
          updated_ast = update_mcp_servers_ast(ast, server_config)
          new_content = Macro.to_string(updated_ast)

          Rewrite.Source.update(source, :content, new_content)

        {:error, _} ->
          # If we can't parse, replace with default
          Rewrite.Source.update(source, :content, default_content)
      end
    end)
  end

  defp update_mcp_servers_ast({:%{}, meta, fields}, server_config) do
    updated_fields =
      case List.keyfind(fields, :mcp_servers, 0) do
        {:mcp_servers, servers_list} ->
          # Add server to existing list
          updated_servers = add_server_to_list(servers_list, server_config)
          List.keyreplace(fields, :mcp_servers, 0, {:mcp_servers, updated_servers})

        nil ->
          # Add new mcp_servers field
          fields ++ [{:mcp_servers, [server_config]}]
      end

    {:%{}, meta, updated_fields}
  end

  defp update_mcp_servers_ast(_ast, server_config) do
    # If it's not a map, wrap it in a map with mcp_servers
    {:%{}, [], [{:mcp_servers, [server_config]}]}
  end

  defp add_server_to_list(servers_list, server_config) when is_list(servers_list) do
    server_name = extract_server_name(server_config)

    # Remove any existing configuration for this server
    filtered_list =
      Enum.reject(servers_list, fn
        atom when is_atom(atom) -> atom == server_name
        {server, _opts} -> server == server_name
        _ -> false
      end)

    # Add the new configuration
    filtered_list ++ [server_config]
  end

  defp add_server_to_list(_, server_config) do
    [server_config]
  end

  defp extract_server_name(atom) when is_atom(atom), do: atom
  defp extract_server_name({server, _opts}) when is_atom(server), do: server

  defp add_setup_notice(igniter, server_atom) do
    config = Catalog.get(server_atom)

    notice = """
    Added MCP server '#{server_atom}' to your project.

    Description: #{config.description}
    """

    notice =
      if config[:setup_instructions] do
        notice <> "\n" <> config.setup_instructions
      else
        notice
      end

    Igniter.add_notice(igniter, notice)
  end
end
