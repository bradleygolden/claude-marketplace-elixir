defmodule Claude.Plugins.Phoenix do
  @moduledoc """
  Phoenix plugin for Claude Code providing comprehensive Phoenix project support.

  This plugin automatically configures Claude Code for Phoenix projects by:

  * **MCP Servers**: Configures Tidewave for Phoenix-specific tooling
  * **Nested Memories**: Sets up usage rules and documentation for Phoenix development
  * **Smart Detection**: Automatically includes LiveView and Ecto rules when those dependencies exist
  * **DaisyUI Integration**: Includes DaisyUI component library documentation for UI development

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.Phoenix]
      }

  Or with options:

      %{
        plugins: [{Claude.Plugins.Phoenix, include_daisyui?: false, port: 4001, tidewave_enabled?: false}]
      }

  The plugin will automatically activate when a `:phoenix` dependency is detected in `mix.exs`.

  ## Options

  * `:include_daisyui?` - Whether to include DaisyUI component library documentation (default: `true`)
  * `:port` - Default port for Tidewave MCP server (default: `4000`). Environment variable `PORT` will still override this.
  * `:tidewave_enabled?` - Whether to enable Tidewave MCP server configuration (default: `true`)
  * `:server_check` - Endpoint module to check for running server. Can be:
    - `false` or `nil` - Disabled (default)
    - Module atom (e.g., `MyAppWeb.Endpoint`) - Check if this endpoint is running

  ## Phoenix Version Support

  * Phoenix >= 1.8: Full support with phoenix-specific usage rules and modern Phoenix patterns
  * Phoenix <= 1.7: Basic support with universal Elixir/OTP usage rules only

  ## Configuration Generated

  * `test/` directory gets Elixir and OTP usage rules (all versions)
  * `lib/app_name/` directory gets business logic rules plus Ecto rules (if detected)
  * `lib/app_name_web/` directory gets Phoenix web rules, DaisyUI docs (if enabled), plus LiveView rules (if detected)
  * Tidewave MCP server configured on specified port (default 4000, overrideable via PORT environment variable)
  """

  @behaviour Claude.Plugin

  def config(opts) do
    igniter = Keyword.get(opts, :igniter)
    include_daisyui? = Keyword.get(opts, :include_daisyui?, true)
    port = Keyword.get(opts, :port, 4000)
    tidewave_enabled? = Keyword.get(opts, :tidewave_enabled?, true)
    server_check = Keyword.get(opts, :server_check, false)

    if detect_phoenix_project?(igniter) do
      app_name = get_app_name(igniter)
      phoenix_version = get_phoenix_version()

      base_config = %{}

      base_config =
        if tidewave_enabled? do
          Map.put(base_config, :mcp_servers, tidewave: [port: "${PORT:-#{port}}"])
        else
          base_config
        end

      base_config =
        Map.put(
          base_config,
          :nested_memories,
          build_nested_memories(igniter, app_name, phoenix_version, include_daisyui?)
        )

      if server_check do
        Map.put(base_config, :hooks, build_server_check_hooks(server_check))
      else
        base_config
      end
    else
      %{}
    end
  end

  defp detect_phoenix_project?(igniter) do
    Igniter.Project.Deps.has_dep?(igniter, :phoenix)
  end

  defp get_app_name(igniter) do
    igniter
    |> Igniter.Project.Module.module_name_prefix()
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp get_phoenix_version do
    try do
      case Application.spec(:phoenix, :vsn) do
        vsn when is_list(vsn) -> List.to_string(vsn)
        _ -> get_phoenix_version_from_lock()
      end
    rescue
      _ -> get_phoenix_version_from_lock()
    end
  end

  defp get_phoenix_version_from_lock do
    case File.read("mix.lock") do
      {:ok, content} ->
        case Regex.run(~r/"phoenix":[^}]*"([\d\.]+)"/, content) do
          [_, version] -> version
          _ -> "1.8.0"
        end

      _ ->
        "1.8.0"
    end
  end

  defp phoenix_supports_phoenix_usage_rules?(version) do
    Version.match?(version, ">= 1.8.0")
  end

  defp build_nested_memories(igniter, app_name, phoenix_version, include_daisyui?) do
    %{
      "test" => build_test_memories(phoenix_version),
      "lib/#{app_name}" => build_app_memories(igniter, phoenix_version),
      "lib/#{app_name}_web" => build_web_memories(igniter, phoenix_version, include_daisyui?)
    }
  end

  defp build_test_memories(_phoenix_version) do
    ["usage_rules:elixir", "usage_rules:otp"]
  end

  defp build_app_memories(igniter, _phoenix_version) do
    base_rules = ["usage_rules:elixir", "usage_rules:otp"]
    base_rules ++ maybe_ecto_rules(igniter)
  end

  defp build_web_memories(igniter, phoenix_version, include_daisyui?) do
    daisyui_docs = maybe_daisyui_docs(include_daisyui?)
    base_rules = ["usage_rules:elixir", "usage_rules:otp"]

    phoenix_rules =
      if phoenix_supports_phoenix_usage_rules?(phoenix_version) do
        ["phoenix:phoenix", "phoenix:html", "phoenix:elixir"]
      else
        []
      end

    daisyui_docs ++
      base_rules ++ phoenix_rules ++ maybe_liveview_rules(igniter) ++ maybe_ecto_rules(igniter)
  end

  defp maybe_daisyui_docs(include_daisyui?) do
    if include_daisyui? do
      [
        {:url, "https://daisyui.com/llms.txt",
         as: "DaisyUI Component Library", cache: "./ai/daisyui/llms.md"}
      ]
    else
      []
    end
  end

  defp maybe_ecto_rules(igniter) do
    if Igniter.Project.Deps.has_dep?(igniter, :ecto) or
         Igniter.Project.Deps.has_dep?(igniter, :ecto_sql) do
      ["phoenix:ecto"]
    else
      []
    end
  end

  defp maybe_liveview_rules(igniter) do
    if Igniter.Project.Deps.has_dep?(igniter, :phoenix_live_view) do
      ["phoenix:liveview"]
    else
      []
    end
  end

  defp build_server_check_hooks(server_check) do
    check_command = build_server_check_command(server_check)

    %{
      session_start: [
        {check_command, when: [:startup, :resume, :clear, :compact]}
      ]
    }
  end

  defp build_server_check_command(server_check) when is_atom(server_check) do
    "claude.phoenix.check #{inspect(server_check)}"
  end
end
