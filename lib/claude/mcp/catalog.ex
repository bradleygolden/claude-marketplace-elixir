defmodule Claude.MCP.Catalog do
  @moduledoc """
  Pre-configured MCP servers with recommended settings.

  Each server in the catalog represents best-practice configuration
  for popular MCP servers. Users can reference these servers by
  atom in their `.claude.exs` file.
  """

  @type server_config :: %{
          type: :stdio | :sse | :http,
          command: String.t() | nil,
          args: list(String.t()),
          url: String.t() | nil,
          headers: map() | nil,
          env: map(),
          description: String.t(),
          setup_instructions: String.t() | nil,
          installer: module() | nil
        }

  @servers %{
    tidewave: %{
      type: :sse,
      url: "http://localhost:${PHOENIX_PORT:-4000}/tidewave/mcp",
      description: "Phoenix development framework integration",
      setup_instructions: """
      Tidewave integrates with your Phoenix application:
      1. Add to your deps in mix.exs: {:tidewave, "~> 0.2.0"}
      2. Run: mix deps.get
      3. Configure in config/dev.exs (see Tidewave docs)
      4. Start your Phoenix server: mix phx.server
      5. MCP endpoint will be at: http://localhost:PORT/tidewave/mcp

      Set PHOENIX_PORT environment variable if not using default port 4000.
      """,
      # Could implement auto-dependency addition later
      installer: nil
    },
    postgres: %{
      type: :stdio,
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-postgres"],
      env: %{
        "CONNECTION_STRING" => "${DATABASE_URL:-postgresql://localhost:5432/dev}"
      },
      description: "PostgreSQL database access (read-only)",
      setup_instructions: """
      Set the DATABASE_URL environment variable to your PostgreSQL connection string.
      Example: export DATABASE_URL="postgresql://user:pass@localhost:5432/mydb"
      """
    },
    filesystem: %{
      type: :stdio,
      command: "npx",
      args: [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "--allowed-directories",
        "${MCP_ALLOWED_DIRS:-$HOME}"
      ],
      env: %{},
      description: "Filesystem access",
      setup_instructions: """
      Set MCP_ALLOWED_DIRS to specify which directories the server can access.
      Example: export MCP_ALLOWED_DIRS="/path/to/project:/another/path"
      Default: $HOME
      """
    },
    github: %{
      type: :stdio,
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-github"],
      env: %{
        "GITHUB_PERSONAL_ACCESS_TOKEN" => "${GITHUB_TOKEN}"
      },
      description: "GitHub API access",
      setup_instructions: """
      Requires a GitHub personal access token.
      1. Create a token at: https://github.com/settings/tokens
      2. Set: export GITHUB_TOKEN="your-token-here"
      """
    },
    memory: %{
      type: :stdio,
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-memory"],
      env: %{},
      description: "Knowledge graph memory server"
    },
    puppeteer: %{
      type: :stdio,
      command: "npx",
      args: ["-y", "@modelcontextprotocol/server-puppeteer"],
      env: %{},
      description: "Browser automation via Puppeteer"
    }
  }

  @doc """
  Get configuration for a specific server.

  ## Examples

      iex> Claude.MCP.Catalog.get(:tidewave)
      %{type: :sse, url: "http://localhost:3000/mcp/sse", ...}
      
      iex> Claude.MCP.Catalog.get(:unknown)
      nil
  """
  @spec get(atom()) :: server_config() | nil
  def get(name) when is_atom(name) do
    Map.get(@servers, name)
  end

  @doc """
  List all available server names.

  ## Examples

      iex> Claude.MCP.Catalog.available()
      [:tidewave, :postgres, :filesystem, :github, :memory, :puppeteer]
  """
  @spec available() :: [atom()]
  def available do
    Map.keys(@servers) |> Enum.sort()
  end

  @doc """
  Check if a server exists in the catalog.

  ## Examples

      iex> Claude.MCP.Catalog.exists?(:tidewave)
      true
      
      iex> Claude.MCP.Catalog.exists?(:unknown)
      false
  """
  @spec exists?(atom()) :: boolean()
  def exists?(name) when is_atom(name) do
    Map.has_key?(@servers, name)
  end

  @doc """
  Get setup instructions for a server.
  """
  @spec setup_instructions(atom()) :: String.t() | nil
  def setup_instructions(name) when is_atom(name) do
    case get(name) do
      %{setup_instructions: instructions} -> instructions
      _ -> nil
    end
  end

  @doc """
  Convert a catalog server config to Claude settings format.
  """
  @spec to_settings_json(atom()) :: map() | nil
  def to_settings_json(name) when is_atom(name) do
    case get(name) do
      nil -> nil
      config -> build_settings_json(config)
    end
  end

  defp build_settings_json(%{type: :stdio} = config) do
    %{
      "command" => config.command,
      "args" => config.args,
      "env" => config.env
    }
    |> maybe_add_field("description", config[:description])
  end

  defp build_settings_json(%{type: type} = config) when type in [:sse, :http] do
    %{
      "type" => to_string(type),
      "url" => config.url
    }
    |> maybe_add_field("headers", config[:headers])
    |> maybe_add_field("env", config[:env])
    |> maybe_add_field("description", config[:description])
  end

  defp maybe_add_field(map, _key, nil), do: map
  defp maybe_add_field(map, _key, empty) when empty == %{}, do: map
  defp maybe_add_field(map, key, value), do: Map.put(map, key, value)
end
