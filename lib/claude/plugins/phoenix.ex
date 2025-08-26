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
        plugins: [{Claude.Plugins.Phoenix, include_daisyui?: false}]
      }

  The plugin will automatically activate when a `:phoenix` dependency is detected in `mix.exs`.

  ## Options

  * `:include_daisyui?` - Whether to include DaisyUI component library documentation (default: `true`)

  ## Phoenix Version Support

  * Phoenix >= 1.7: Full support with usage rules and modern Phoenix patterns
  * Phoenix < 1.7: Basic support without usage rules (which weren't available in older versions)

  ## Configuration Generated

  * `test/` directory gets Elixir and OTP usage rules (Phoenix >= 1.7 only)
  * `lib/app_name/` directory gets business logic rules plus Ecto rules (if detected)
  * `lib/app_name_web/` directory gets Phoenix web rules, DaisyUI docs (if enabled), plus LiveView rules (if detected)
  * Tidewave MCP server configured on port 4000 (or PORT environment variable)
  """

  @behaviour Claude.Plugin

  def config(opts) do
    igniter = Keyword.get(opts, :igniter)
    include_daisyui? = Keyword.get(opts, :include_daisyui?, true)

    if detect_phoenix_project?(igniter) do
      app_name = get_app_name(igniter)
      phoenix_version = get_phoenix_version()

      %{
        mcp_servers: [tidewave: [port: "${PORT:-4000}"]],
        nested_memories:
          build_nested_memories(igniter, app_name, phoenix_version, include_daisyui?)
      }
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
    case File.read("mix.lock") do
      {:ok, content} ->
        case Regex.run(~r/"phoenix":[^}]*"([\d\.]+)"/, content) do
          [_, version] -> version
          _ -> "0.0.0"
        end

      _ ->
        "0.0.0"
    end
  end

  defp phoenix_supports_usage_rules?(version) do
    Version.match?(version, ">= 1.7.0")
  end

  defp build_nested_memories(igniter, app_name, phoenix_version, include_daisyui?) do
    %{
      "test" => build_test_memories(phoenix_version),
      "lib/#{app_name}" => build_app_memories(igniter, phoenix_version),
      "lib/#{app_name}_web" => build_web_memories(igniter, phoenix_version, include_daisyui?)
    }
  end

  defp build_test_memories(phoenix_version) do
    if phoenix_supports_usage_rules?(phoenix_version) do
      ["usage_rules:elixir", "usage_rules:otp"]
    else
      []
    end
  end

  defp build_app_memories(igniter, phoenix_version) do
    base_rules =
      if phoenix_supports_usage_rules?(phoenix_version) do
        ["usage_rules:elixir", "usage_rules:otp"]
      else
        []
      end

    base_rules ++ maybe_ecto_rules(igniter)
  end

  defp build_web_memories(igniter, phoenix_version, include_daisyui?) do
    daisyui_docs = maybe_daisyui_docs(include_daisyui?)

    base_rules =
      if phoenix_supports_usage_rules?(phoenix_version) do
        ["usage_rules:elixir", "usage_rules:otp"]
      else
        []
      end

    phoenix_rules = ["phoenix:phoenix", "phoenix:html", "phoenix:elixir"]

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
end
