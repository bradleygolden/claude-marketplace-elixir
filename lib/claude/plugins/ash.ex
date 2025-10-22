defmodule Claude.Plugins.Ash do
  @moduledoc """
  Ash plugin for Claude Code providing comprehensive support for Ash Framework projects.

  This plugin automatically configures Claude Code for Ash projects by:

  * **Hooks**: Runs `ash.codegen --check` after file modifications to ensure generated code is up to date
  * **Nested Memories**: Intelligently applies Ash and extension usage rules based on detected dependencies
  * **Smart Detection**: Automatically activates when the `:ash` dependency is detected in `mix.exs`
  * **Extension Support**: Conditionally includes rules for ash_postgres, ash_phoenix, ash_ai, ash_oban, and ash_json_api

  ## Usage

  Add to your `.claude.exs`:

      %{
        plugins: [Claude.Plugins.Ash]
      }

  Or with options:

      %{
        plugins: [{Claude.Plugins.Ash, []}]
      }

  The plugin will automatically activate when an `:ash` dependency is detected in `mix.exs`.

  ## Supported Extensions

  The plugin automatically detects and applies usage rules for these Ash extensions:

  * **ash_postgres**: Database layer rules applied to `lib/<app_name>` and `priv/repo/migrations`
  * **ash_phoenix**: Web integration rules applied to `lib/<app_name>_web`
  * **ash_ai**: AI/LLM feature rules applied to `lib/<app_name>`
  * **ash_oban**: Background job rules applied to `lib/<app_name>`
  * **ash_json_api**: JSON:API rules applied to `lib/<app_name>_web`

  ## Configuration Generated

  * `post_tool_use` hook: Runs `ash.codegen --check` after write/edit operations to validate generated code
  * `nested_memories`: Applies relevant Ash and extension usage rules to appropriate directories
  """

  @behaviour Claude.Plugin

  @impl Claude.Plugin
  def detect(nil), do: true  # At runtime, assume Ash is present
  def detect(igniter), do: Igniter.Project.Deps.has_dep?(igniter, :ash)

  @impl Claude.Plugin
  def config(_opts) do
    app_name = get_app_name()

    %{
      hooks: %{
        post_tool_use: [
          {"ash.codegen --check", when: [:write, :edit, :multi_edit]}
        ]
      },
      nested_memories: build_nested_memories(app_name),
      inline_usage_rules: ["ash"]
    }
  end

  defp detect_ash_postgres? do
    Code.ensure_loaded?(AshPostgres)
  end

  defp detect_ash_phoenix? do
    Code.ensure_loaded?(AshPhoenix)
  end

  defp detect_ash_ai? do
    Code.ensure_loaded?(AshAi)
  end

  defp detect_ash_oban? do
    Code.ensure_loaded?(AshOban)
  end

  defp detect_ash_json_api? do
    Code.ensure_loaded?(AshJsonApi)
  end

  defp get_app_name do
    Mix.Project.config()[:app] |> to_string()
  end

  defp build_nested_memories(app_name) do
    base_memories = %{
      "lib/#{app_name}" => build_app_memories(),
      "test" => ["ash"]
    }

    base_memories
    |> maybe_add_web_memories(app_name)
    |> maybe_add_migration_memories()
  end

  defp build_app_memories do
    base_rules = ["ash"]

    base_rules
    |> maybe_add_postgres_rules()
    |> maybe_add_ai_rules()
    |> maybe_add_oban_rules()
  end

  defp maybe_add_web_memories(memories, app_name) do
    web_rules = build_web_memories()

    if Enum.empty?(web_rules) do
      memories
    else
      Map.put(memories, "lib/#{app_name}_web", web_rules)
    end
  end

  defp build_web_memories do
    []
    |> maybe_add_phoenix_rules()
    |> maybe_add_json_api_rules()
  end

  defp maybe_add_migration_memories(memories) do
    if detect_ash_postgres?() do
      Map.put(memories, "priv/repo/migrations", ["ash_postgres"])
    else
      memories
    end
  end

  defp maybe_add_postgres_rules(rules) do
    if detect_ash_postgres?() do
      rules ++ ["ash_postgres"]
    else
      rules
    end
  end

  defp maybe_add_phoenix_rules(rules) do
    if detect_ash_phoenix?() do
      rules ++ ["ash_phoenix"]
    else
      rules
    end
  end

  defp maybe_add_ai_rules(rules) do
    if detect_ash_ai?() do
      rules ++ ["ash_ai"]
    else
      rules
    end
  end

  defp maybe_add_oban_rules(rules) do
    if detect_ash_oban?() do
      rules ++ ["ash_oban"]
    else
      rules
    end
  end

  defp maybe_add_json_api_rules(rules) do
    if detect_ash_json_api?() do
      rules ++ ["ash_json_api"]
    else
      rules
    end
  end
end
