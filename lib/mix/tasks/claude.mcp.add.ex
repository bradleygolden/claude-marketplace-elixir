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
      mix claude.mcp.add postgres
      mix claude.mcp.add filesystem

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
            
            igniter
            |> update_claude_exs(relative_exs_path, server_atom)
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

  defp update_claude_exs(igniter, relative_path, server_atom) do
    # Create default content if file doesn't exist
    default_content = """
    %{
      mcp_servers: [#{inspect(server_atom)}]
    }
    """

    igniter
    |> Igniter.create_or_update_file(relative_path, default_content, fn source ->
      content = Rewrite.Source.get(source, :content)

      # Parse the existing content
      case Code.string_to_quoted(content) do
        {:ok, ast} ->
          # Update the AST to add the server
          updated_ast = update_mcp_servers_ast(ast, server_atom)
          new_content = Macro.to_string(updated_ast)

          Rewrite.Source.update(source, :content, new_content)

        {:error, _} ->
          # If we can't parse, replace with default
          Rewrite.Source.update(source, :content, default_content)
      end
    end)
  end

  defp update_mcp_servers_ast({:%{}, meta, fields}, server_atom) do
    updated_fields =
      case List.keyfind(fields, :mcp_servers, 0) do
        {:mcp_servers, servers_list} ->
          # Add server to existing list
          updated_servers = add_server_to_list(servers_list, server_atom)
          List.keyreplace(fields, :mcp_servers, 0, {:mcp_servers, updated_servers})

        nil ->
          # Add new mcp_servers field
          fields ++ [{:mcp_servers, [server_atom]}]
      end

    {:%{}, meta, updated_fields}
  end

  defp update_mcp_servers_ast(_ast, server_atom) do
    # If it's not a map, wrap it in a map with mcp_servers
    {:%{}, [], [{:mcp_servers, [server_atom]}]}
  end

  defp add_server_to_list(servers_list, server_atom) when is_list(servers_list) do
    if server_atom in servers_list do
      servers_list
    else
      servers_list ++ [server_atom]
    end
  end

  defp add_server_to_list(_, server_atom) do
    [server_atom]
  end

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
