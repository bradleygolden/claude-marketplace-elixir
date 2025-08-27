defmodule Claude.MCP.ConfigTest do
  use Claude.ClaudeCodeCase

  alias Claude.MCP.Config

  describe "write_mcp_config/2 - tidewave configuration" do
    test "configures tidewave with HTTP transport by default" do
      igniter = test_project()
      servers = [:tidewave]

      igniter = Config.write_mcp_config(igniter, servers)

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)

      {:ok, config} = Jason.decode(content)

      assert %{
               "mcpServers" => %{
                 "tidewave" => %{
                   "type" => "http",
                   "url" => "http://localhost:4000/tidewave/mcp"
                 }
               }
             } = config
    end

    test "configures tidewave with custom port" do
      igniter = test_project()
      servers = [tidewave: [port: 3000]]

      igniter = Config.write_mcp_config(igniter, servers)

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)

      {:ok, config} = Jason.decode(content)

      assert %{
               "mcpServers" => %{
                 "tidewave" => %{
                   "type" => "http",
                   "url" => "http://localhost:3000/tidewave/mcp"
                 }
               }
             } = config
    end

    test "configures tidewave with environment variable port substitution" do
      igniter = test_project()
      servers = [tidewave: [port: "${PORT:-4000}"]]

      igniter = Config.write_mcp_config(igniter, servers)

      assert Igniter.exists?(igniter, ".mcp.json")

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)

      {:ok, config} = Jason.decode(content)

      assert %{
               "mcpServers" => %{
                 "tidewave" => %{
                   "type" => "http",
                   "url" => "http://localhost:${PORT:-4000}/tidewave/mcp"
                 }
               }
             } = config
    end

    test "excludes disabled tidewave servers" do
      igniter = test_project()
      servers = [tidewave: [port: 4000, enabled?: false]]

      igniter = Config.write_mcp_config(igniter, servers)

      if Igniter.exists?(igniter, ".mcp.json") do
        source = igniter.rewrite |> Rewrite.source!(".mcp.json")
        content = Rewrite.Source.get(source, :content)

        {:ok, config} = Jason.decode(content)

        assert %{"mcpServers" => servers_map} = config
        refute Map.has_key?(servers_map, "tidewave")
      else
        # No .mcp.json file should be created if no servers are enabled
        assert true
      end
    end
  end

  describe "remove_mcp_server/2" do
    test "removes tidewave server from existing config" do
      igniter = test_project()
      servers = [:tidewave, :other_server]

      igniter =
        igniter
        |> Config.write_mcp_config(servers)
        |> Config.remove_mcp_server(:tidewave)

      source = igniter.rewrite |> Rewrite.source!(".mcp.json")
      content = Rewrite.Source.get(source, :content)

      {:ok, config} = Jason.decode(content)

      assert %{"mcpServers" => servers_map} = config
      refute Map.has_key?(servers_map, "tidewave")
      assert Map.has_key?(servers_map, "other_server")
    end
  end
end
