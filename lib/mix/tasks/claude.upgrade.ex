defmodule Mix.Tasks.Claude.Upgrade do
  @moduledoc """
  Upgrades Claude configuration from older versions to the current version.

  This task handles breaking changes between Claude versions, ensuring smooth
  migration while preserving user customizations.

  ## Usage

      mix claude.upgrade

  This task is automatically invoked when using `mix igniter.upgrade` if Claude
  needs to be upgraded.
  """

  use Igniter.Mix.Task

  @shortdoc "Upgrades Claude configuration from older versions"

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    from =
      igniter.assigns[:args][:options][:from] ||
        get_in(igniter, [Access.key(:args), Access.key(:options), :from])

    to =
      igniter.assigns[:args][:options][:to] ||
        get_in(igniter, [Access.key(:args), Access.key(:options), :to]) || "0.3.0"

    cond do
      not is_nil(from) and to == "0.3.0" and Version.compare(from, "0.3.0") == :lt ->
        upgrade_to_0_3_0(igniter)

      not is_nil(from) ->
        igniter

      true ->
        igniter
    end
  end

  defp upgrade_to_0_3_0(igniter) do
    igniter
    |> migrate_hooks_configuration()
    |> run_claude_install()
    |> add_upgrade_notices()
  end

  defp migrate_hooks_configuration(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      igniter
      |> Igniter.update_file(claude_exs_path, fn source ->
        content = Rewrite.Source.get(source, :content)

        case Code.eval_string(content) do
          {config, _bindings} when is_map(config) ->
            updated_config = migrate_hooks_in_config(config)

            if updated_config != config do
              new_content = inspect(updated_config, pretty: true, limit: :infinity)
              Rewrite.Source.update(source, :content, new_content)
            else
              source
            end

          _ ->
            source
        end
      end)
    else
      igniter
    end
  end

  defp migrate_hooks_in_config(config) do
    case Map.get(config, :hooks) do
      hooks when is_list(hooks) ->
        migrated_hooks = migrate_hooks_list_to_map(hooks)
        Map.put(config, :hooks, migrated_hooks)

      hooks when is_map(hooks) ->
        config

      _ ->
        config
    end
  end

  defp migrate_hooks_list_to_map(hooks_list) do
    default_hooks = %{
      stop: [:compile, :format],
      subagent_stop: [:compile, :format],
      post_tool_use: [:compile, :format],
      pre_tool_use: [:compile, :format, :unused_deps]
    }

    has_formatter = Enum.any?(hooks_list, &module_matches?(&1, "ElixirFormatter"))
    has_compiler = Enum.any?(hooks_list, &module_matches?(&1, "CompilationChecker"))
    has_precommit = Enum.any?(hooks_list, &module_matches?(&1, "PreCommitCheck"))

    cond do
      has_formatter and has_compiler and has_precommit ->
        default_hooks

      length(hooks_list) > 0 ->
        Map.put(default_hooks, :custom_hooks_detected, true)

      true ->
        %{}
    end
  end

  defp module_matches?(module_atom, name_part) when is_atom(module_atom) do
    module_atom
    |> Atom.to_string()
    |> String.contains?(name_part)
  end

  defp module_matches?(_, _), do: false

  defp run_claude_install(igniter) do
    Igniter.compose_task(igniter, "claude.install", [])
  end

  defp add_upgrade_notices(igniter) do
    igniter
    |> Igniter.add_notice("""
    Claude has been upgraded to v0.3.0! 🎉

    ## Major Changes:

    ### Hook System Overhaul
    - Hooks now use atom-based shortcuts (`:compile`, `:format`, `:unused_deps`)
    - Old class-based hook modules have been replaced with a unified dispatcher
    - Your `.claude.exs` has been migrated to the new format

    ### New Features Available:
    - Mix task generators: `mix claude.gen.subagent`
    - Comprehensive cheatsheets and documentation
    - Enhanced MCP server support
    - Usage rules integration from dependencies

    ### Documentation:
    - All documentation has been restructured with `guide-` prefixes
    - New cheatsheets available for quick reference
    - See the updated README.md for current capabilities

    Run `mix claude.install` if you need to regenerate your Claude settings.
    """)
  end
end
