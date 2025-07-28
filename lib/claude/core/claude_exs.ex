defmodule Claude.Core.ClaudeExs do
  @moduledoc """
  Handles loading and processing of .claude.exs configuration files.

  This module provides functionality to read and evaluate .claude.exs files,
  which contain project-specific Claude configuration including subagents.
  """

  alias Claude.Core.Project
  alias Claude.Subagents.Subagent

  @type config :: %{
          optional(:hooks) => [module()],
          optional(:subagents) => [subagent_config()],
          optional(:mcp_servers) => [atom() | {atom(), keyword()}]
        }

  @type subagent_config :: %{
          name: String.t(),
          description: String.t(),
          prompt: String.t(),
          tools: [atom()],
          usage_rules: [String.t()]
        }

  @doc """
  Loads the .claude.exs configuration from the project root.

  Returns `{:ok, config}` if the file exists and is valid, or
  `{:error, reason}` if there's an error.
  """
  @spec load() :: {:ok, config()} | {:error, term()}
  def load do
    case Project.claude_exs_path() do
      {:ok, path} ->
        load_from_path(path)

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Reads the .claude.exs configuration from the project root.

  This is an alias for `load/0` for consistency with other modules.
  """
  @spec read() :: {:ok, config()} | {:error, term()}
  def read, do: load()

  @doc """
  Writes configuration to .claude.exs file.
  """
  @spec write(config()) :: :ok | {:error, term()}
  def write(config) when is_map(config) do
    case validate_config(config) do
      {:ok, _} ->
        case Project.claude_exs_path() do
          {:ok, path} ->
            content = """
            %{
            #{format_config(config)}
            }
            """

            File.write(path, content)

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Loads the .claude.exs configuration from a specific path.
  """
  @spec load_from_path(String.t()) :: {:ok, config()} | {:error, term()}
  def load_from_path(path) do
    if File.exists?(path) do
      try do
        {result, _binding} = Code.eval_file(path)
        validate_config(result)
      rescue
        e ->
          {:error, {:eval_error, Exception.message(e)}}
      end
    else
      {:error, :not_found}
    end
  end

  @doc """
  Retrieves the subagents configuration from the loaded config.
  """
  @spec get_subagents(config()) :: [subagent_config()]
  def get_subagents(config) do
    Map.get(config, :subagents, [])
  end

  @doc """
  Converts a subagent config map to a Subagent struct.
  """
  @spec subagent_from_config(subagent_config()) :: {:ok, Subagent.t()} | {:error, term()}
  def subagent_from_config(config) do
    with :ok <- validate_subagent_config(config) do
      subagent = %Subagent{
        name: config.name,
        description: config.description,
        prompt: config.prompt,
        tools: config[:tools] || [],
        plugins: build_plugins(config)
      }

      {:ok, subagent}
    end
  end

  defp validate_config(config) when is_map(config) do
    case validate_config_keys(config) do
      :ok -> {:ok, config}
      error -> error
    end
  end

  defp validate_config(_), do: {:error, "Configuration must be a map"}

  defp validate_config_keys(config) do
    valid_keys = [:hooks, :subagents, :mcp_servers]
    invalid_keys = Map.keys(config) -- valid_keys

    if invalid_keys == [] do
      with :ok <- validate_subagents(Map.get(config, :subagents, [])),
           :ok <- validate_mcp_servers(Map.get(config, :mcp_servers, [])) do
        :ok
      end
    else
      {:error, "Invalid configuration keys: #{inspect(invalid_keys)}"}
    end
  end

  defp validate_subagents(subagents) when is_list(subagents) do
    Enum.reduce_while(subagents, :ok, fn subagent, _acc ->
      case validate_subagent_config(subagent) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end

  defp validate_subagents(_), do: {:error, "Subagents must be a list"}

  defp validate_mcp_servers(servers) when is_list(servers) do
    Enum.reduce_while(servers, :ok, fn
      server, _acc when is_atom(server) ->
        {:cont, :ok}

      {server, opts}, _acc when is_atom(server) and is_list(opts) ->
        case validate_mcp_server_opts(opts) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end

      _, _acc ->
        {:halt, {:error, "MCP servers must be atoms or tuples like {:server_name, [port: 5000]}"}}
    end)
  end

  defp validate_mcp_servers(_), do: {:error, "MCP servers must be a list"}

  defp validate_mcp_server_opts(opts) when is_list(opts) do
    # Check all keys are valid
    valid_keys = [:port]
    
    Enum.reduce_while(opts, :ok, fn
      {:port, port}, _acc ->
        case validate_port(port) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end
        
      {key, _}, _acc ->
        {:halt, {:error, "Invalid option #{inspect(key)}. Valid options are: #{inspect(valid_keys)}"}}
    end)
  end

  defp validate_mcp_server_opts(_), do: {:error, "MCP server options must be a keyword list"}

  defp validate_port(port) when is_integer(port) and port > 0 and port <= 65535, do: :ok
  defp validate_port(_), do: {:error, "Port must be an integer between 1 and 65535"}

  defp validate_subagent_config(config) when is_map(config) do
    required_keys = [:name, :description, :prompt]
    optional_keys = [:tools, :usage_rules, :plugins]
    all_keys = required_keys ++ optional_keys

    with :ok <- validate_required_keys(config, required_keys),
         :ok <- validate_allowed_keys(config, all_keys),
         :ok <- validate_name(config[:name]),
         :ok <- validate_description(config[:description]),
         :ok <- validate_prompt(config[:prompt]),
         :ok <- validate_tools(config[:tools]),
         :ok <- validate_usage_rules(config[:usage_rules]),
         :ok <- validate_plugins(config[:plugins]) do
      :ok
    end
  end

  defp validate_subagent_config(_), do: {:error, "Subagent config must be a map"}

  defp validate_required_keys(config, required_keys) do
    missing_keys = required_keys -- Map.keys(config)

    if missing_keys == [] do
      :ok
    else
      {:error, "Missing required keys: #{inspect(missing_keys)}"}
    end
  end

  defp validate_allowed_keys(config, allowed_keys) do
    invalid_keys = Map.keys(config) -- allowed_keys

    if invalid_keys == [] do
      :ok
    else
      {:error, "Invalid keys: #{inspect(invalid_keys)}"}
    end
  end

  defp validate_name(name) when is_binary(name) and byte_size(name) > 0, do: :ok
  defp validate_name(_), do: {:error, "Name must be a non-empty string"}

  defp validate_description(desc) when is_binary(desc) and byte_size(desc) > 0, do: :ok
  defp validate_description(_), do: {:error, "Description must be a non-empty string"}

  defp validate_prompt(prompt) when is_binary(prompt) and byte_size(prompt) > 0, do: :ok
  defp validate_prompt(_), do: {:error, "Prompt must be a non-empty string"}

  defp validate_tools(nil), do: :ok

  defp validate_tools(tools) when is_list(tools) do
    if Enum.all?(tools, &is_atom/1) do
      :ok
    else
      {:error, "Tools must be a list of atoms"}
    end
  end

  defp validate_tools(_), do: {:error, "Tools must be a list of atoms"}

  defp validate_usage_rules(nil), do: :ok

  defp validate_usage_rules(rules) when is_list(rules) do
    if Enum.all?(rules, &is_binary/1) do
      :ok
    else
      {:error, "Usage rules must be a list of strings"}
    end
  end

  defp validate_usage_rules(_), do: {:error, "Usage rules must be a list of strings"}

  defp validate_plugins(nil), do: :ok

  defp validate_plugins(plugins) when is_list(plugins) do
    if Enum.all?(plugins, &valid_plugin_spec?/1) do
      :ok
    else
      {:error, "Plugins must be a list of {module, map} tuples"}
    end
  end

  defp validate_plugins(_), do: {:error, "Plugins must be a list"}

  defp valid_plugin_spec?({module, opts}) when is_atom(module) and is_map(opts), do: true
  defp valid_plugin_spec?(_), do: false

  defp build_plugins(config) do
    case config[:usage_rules] do
      nil ->
        []

      rules when is_list(rules) ->
        [{Claude.Subagents.Plugins.UsageRules, %{deps: rules}}]
    end
  end

  defp format_config(config) do
    config
    |> Enum.map(&format_config_entry/1)
    |> Enum.join(",\n")
  end

  defp format_config_entry({:hooks, hooks}) when is_list(hooks) do
    formatted_hooks =
      hooks
      |> Enum.map(&inspect/1)
      |> Enum.join(",\n    ")

    "  hooks: [\n    #{formatted_hooks}\n  ]"
  end

  defp format_config_entry({:mcp_servers, servers}) when is_list(servers) do
    formatted_servers =
      servers
      |> Enum.map(&format_mcp_server/1)
      |> Enum.join(", ")

    "  mcp_servers: [#{formatted_servers}]"
  end

  defp format_config_entry({:subagents, subagents}) when is_list(subagents) do
    formatted_subagents =
      subagents
      |> Enum.map(&format_subagent/1)
      |> Enum.join(",\n    ")

    "  subagents: [\n    #{formatted_subagents}\n  ]"
  end

  defp format_config_entry({key, value}) do
    "  #{key}: #{inspect(value)}"
  end

  defp format_subagent(subagent) when is_map(subagent) do
    "%{\n" <>
      (subagent
       |> Enum.map(fn {k, v} -> "      #{k}: #{inspect(v)}" end)
       |> Enum.join(",\n")) <>
      "\n    }"
  end

  defp format_mcp_server(server) when is_atom(server), do: inspect(server)

  defp format_mcp_server({server, opts}) when is_atom(server) and is_list(opts) do
    "{#{inspect(server)}, #{inspect(opts)}}"
  end
end
