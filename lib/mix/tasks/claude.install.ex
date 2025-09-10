defmodule Mix.Tasks.Claude.Install do
  @shortdoc "Setup Claude for your Elixir project"

  @moduledoc """
  Setup Claude for your Elixir project.

  This task is automatically run when you execute:

      mix igniter.install claude

  It sets up Claude Code integration for your Elixir project by:

  1. Creating a .claude.exs configuration file for project-specific settings
  2. Installing all Claude hooks for auto-formatting and compilation checking
  3. Adding usage_rules dependency for better LLM integration
  4. Syncing usage rules to CLAUDE.md for enhanced code assistance
  5. Generating any configured subagents for specialized assistance
  6. Configuring MCP servers (like Tidewave for Phoenix projects)
  7. Ensuring your project is properly configured for Claude Code integration

  ## Example

  ```sh
  mix igniter.install claude
  ```
  """

  use Igniter.Mix.Task

  alias Claude.MCP.Config

  @usage_rules_version "~> 0.1"

  @tool_atom_to_string %{
    bash: "Bash",
    edit: "Edit",
    glob: "Glob",
    grep: "Grep",
    ls: "LS",
    multi_edit: "MultiEdit",
    notebook_edit: "NotebookEdit",
    notebook_read: "NotebookRead",
    read: "Read",
    task: "Task",
    todo_write: "TodoWrite",
    web_fetch: "WebFetch",
    web_search: "WebSearch",
    write: "Write"
  }

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix igniter.install claude",
      only: [:dev],
      dep_opts: [runtime: false]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    igniter
    |> Igniter.assign(claude_exs_path: ".claude.exs", claude_dir_path: ".claude")
    |> create_claude_exs()
    |> add_usage_rules_dependency()
    |> install_hooks()
    |> copy_wrapper_script()
    |> sync_usage_rules()
    |> generate_nested_memories()
    |> generate_subagents()
    |> install_commands()
    |> setup_tidewave_if_configured()
    |> add_claude_exs_to_formatter()
  end

  defp create_claude_exs(igniter) do
    path = igniter.assigns[:claude_exs_path]

    if Igniter.exists?(igniter, path) do
      igniter
      |> ensure_default_hooks(path)
      |> ensure_base_plugin(path)
      |> ensure_phoenix_plugin(path)
      |> ensure_ash_plugin(path)
      |> ensure_credo_plugin(path)
      |> ensure_dialyzer_plugin(path)
      |> check_meta_agent_and_notify(path)
    else
      Igniter.create_new_file(
        igniter,
        path,
        claude_exs_template(igniter)
      )
    end
  end

  defp add_usage_rules_dependency(igniter) do
    Igniter.Project.Deps.add_dep(
      igniter,
      {:usage_rules, @usage_rules_version, only: [:dev]},
      on_exists: :skip
    )
  end

  defp add_claude_exs_to_formatter(igniter) do
    default_formatter = """
    [
      inputs: [".claude.exs", "{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
    ]
    """

    igniter
    |> Igniter.include_or_create_file(".formatter.exs", default_formatter)
    |> Igniter.update_elixir_file(".formatter.exs", fn zipper ->
      zipper
      |> Sourceror.Zipper.down()
      |> case do
        nil ->
          code =
            quote do
              [inputs: [".claude.exs"]]
            end

          {:ok, Igniter.Code.Common.add_code(zipper, code)}

        zipper ->
          zipper
          |> Sourceror.Zipper.rightmost()
          |> Igniter.Code.Keyword.put_in_keyword(
            [:inputs],
            [".claude.exs"],
            fn nested_zipper ->
              Igniter.Code.List.prepend_new_to_list(
                nested_zipper,
                ".claude.exs"
              )
            end
          )
          |> case do
            {:ok, zipper} -> zipper
            :error -> zipper
          end
      end
    end)
  end

  defp ensure_default_hooks(igniter, path) do
    case read_and_eval_claude_exs(igniter, path) do
      {:ok, config} when is_map(config) ->
        hooks = Map.get(config, :hooks, %{})

        if is_list(hooks) do
          Igniter.add_issue(igniter, """
          Your .claude.exs is using an outdated hooks format.

          Please manually update your .claude.exs file to use the new format:

          %{
            hooks: %{
              stop: [:compile, :format],
              subagent_stop: [:compile, :format],
              post_tool_use: [:compile, :format],
              pre_tool_use: [:compile, :format, :unused_deps]
            }
          }

          Then run `mix claude.install` again to regenerate the hook scripts.
          """)
        else
          igniter
        end

      _ ->
        igniter
    end
  end

  defp ensure_base_plugin(igniter, path) do
    case read_and_eval_claude_exs(igniter, path) do
      {:ok, config} when is_map(config) ->
        plugins = Map.get(config, :plugins, [])

        has_base_plugin =
          Enum.any?(plugins, fn
            Claude.Plugins.Base -> true
            {Claude.Plugins.Base, _} -> true
            _ -> false
          end)

        if not has_base_plugin do
          updated_plugins = [Claude.Plugins.Base | plugins]
          updated_config = Map.put(config, :plugins, updated_plugins)

          Igniter.update_file(igniter, path, fn source ->
            Rewrite.Source.update(
              source,
              :content,
              inspect(updated_config, pretty: true, limit: :infinity)
            )
          end)
        else
          igniter
        end

      _ ->
        igniter
    end
  end

  defp ensure_phoenix_plugin(igniter, path) do
    if Igniter.Project.Deps.has_dep?(igniter, :phoenix) do
      case read_and_eval_claude_exs(igniter, path) do
        {:ok, config} when is_map(config) ->
          plugins = Map.get(config, :plugins, [])
          mcp_servers = Map.get(config, :mcp_servers, [])

          has_phoenix_plugin =
            Enum.any?(plugins, fn
              Claude.Plugins.Phoenix -> true
              {Claude.Plugins.Phoenix, _} -> true
              _ -> false
            end)

          has_explicit_tidewave =
            Enum.any?(mcp_servers, fn
              :tidewave -> true
              {:tidewave, _} -> true
              _ -> false
            end)

          if not has_phoenix_plugin do
            phoenix_plugin =
              if has_explicit_tidewave do
                {Claude.Plugins.Phoenix, [tidewave_enabled?: false]}
              else
                Claude.Plugins.Phoenix
              end

            updated_plugins = plugins ++ [phoenix_plugin]
            updated_config = Map.put(config, :plugins, updated_plugins)

            Igniter.update_file(igniter, path, fn source ->
              Rewrite.Source.update(
                source,
                :content,
                inspect(updated_config, pretty: true, limit: :infinity)
              )
            end)
          else
            igniter
          end

        _ ->
          igniter
      end
    else
      igniter
    end
  end

  defp ensure_ash_plugin(igniter, path) do
    if Igniter.Project.Deps.has_dep?(igniter, :ash) do
      case read_and_eval_claude_exs(igniter, path) do
        {:ok, config} when is_map(config) ->
          plugins = Map.get(config, :plugins, [])

          has_ash_plugin =
            Enum.any?(plugins, fn
              Claude.Plugins.Ash -> true
              {Claude.Plugins.Ash, _} -> true
              _ -> false
            end)

          if not has_ash_plugin do
            updated_plugins = plugins ++ [Claude.Plugins.Ash]
            updated_config = Map.put(config, :plugins, updated_plugins)

            Igniter.update_file(igniter, path, fn source ->
              Rewrite.Source.update(
                source,
                :content,
                inspect(updated_config, pretty: true, limit: :infinity)
              )
            end)
          else
            igniter
          end

        _ ->
          igniter
      end
    else
      igniter
    end
  end

  defp ensure_credo_plugin(igniter, path) do
    if Igniter.Project.Deps.has_dep?(igniter, :credo) do
      case read_and_eval_claude_exs(igniter, path) do
        {:ok, config} when is_map(config) ->
          plugins = Map.get(config, :plugins, [])

          has_credo_plugin =
            Enum.any?(plugins, fn
              Claude.Plugins.Credo -> true
              {Claude.Plugins.Credo, _} -> true
              _ -> false
            end)

          if not has_credo_plugin do
            updated_plugins = plugins ++ [Claude.Plugins.Credo]
            updated_config = Map.put(config, :plugins, updated_plugins)

            Igniter.update_file(igniter, path, fn source ->
              Rewrite.Source.update(
                source,
                :content,
                inspect(updated_config, pretty: true, limit: :infinity)
              )
            end)
          else
            igniter
          end

        _ ->
          igniter
      end
    else
      igniter
    end
  end

  defp ensure_dialyzer_plugin(igniter, path) do
    if Igniter.Project.Deps.has_dep?(igniter, :dialyxir) do
      case read_and_eval_claude_exs(igniter, path) do
        {:ok, config} when is_map(config) ->
          plugins = Map.get(config, :plugins, [])

          has_dialyzer_plugin =
            Enum.any?(plugins, fn
              Claude.Plugins.Dialyzer -> true
              {Claude.Plugins.Dialyzer, _} -> true
              _ -> false
            end)

          if not has_dialyzer_plugin do
            updated_plugins = plugins ++ [Claude.Plugins.Dialyzer]
            updated_config = Map.put(config, :plugins, updated_plugins)

            Igniter.update_file(igniter, path, fn source ->
              Rewrite.Source.update(
                source,
                :content,
                inspect(updated_config, pretty: true, limit: :infinity)
              )
            end)
          else
            igniter
          end

        _ ->
          igniter
      end
    else
      igniter
    end
  end

  defp read_hooks_from_claude_exs(igniter) do
    claude_exs_path = igniter.assigns[:claude_exs_path]

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_config_with_plugins(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          hooks = Map.get(config, :hooks, [])

          has_reporters? = Map.has_key?(config, :reporters)

          parsed_hooks =
            case hooks do
              hooks_map when is_map(hooks_map) ->
                hooks_map
                |> Enum.flat_map(fn
                  {event_type, event_configs} when is_list(event_configs) ->
                    event_configs
                    |> Enum.with_index()
                    |> Enum.map(fn {hook_spec, index} ->
                      parse_hook_spec(hook_spec, event_type, index)
                    end)

                  {_event_type, _non_list} ->
                    []
                end)
                |> Enum.reject(&is_nil/1)

              _ ->
                []
            end

          igniter
          |> Igniter.assign(claude_exs_hooks: parsed_hooks)
          |> Igniter.assign(has_reporters: has_reporters?)

        _ ->
          igniter
          |> Igniter.assign(claude_exs_hooks: [])
          |> Igniter.assign(has_reporters: false)
      end
    else
      igniter
      |> Igniter.assign(claude_exs_hooks: [])
      |> Igniter.assign(has_reporters: false)
    end
  end

  defp parse_hook_spec(task, event_type, index) when is_atom(task) do
    expanded = Claude.Hooks.Defaults.expand_hook(task, event_type)
    parse_hook_spec(expanded, event_type, index)
  end

  defp parse_hook_spec(task, event_type, index) when is_binary(task) do
    id = :"#{event_type}_#{index}"
    description = "Mix task: #{task}"
    {:mix_task, task, event_type, "*", description, [id: id]}
  end

  defp parse_hook_spec({task, opts}, event_type, index) when is_binary(task) and is_list(opts) do
    id = :"#{event_type}_#{index}"

    matcher =
      if event_type in [:session_start, :session_end],
        do: "*",
        else: format_matcher(opts[:when] || "*")

    description = "Mix task: #{task}"
    {:mix_task, task, event_type, matcher, description, [id: id]}
  end

  defp parse_hook_spec(_, _, _), do: nil

  defp claude_exs_template(igniter) do
    base_plugins = ["Claude.Plugins.Base"]

    plugins_list =
      base_plugins ++
        if(Igniter.Project.Deps.has_dep?(igniter, :phoenix),
          do: ["Claude.Plugins.Phoenix"],
          else: []
        ) ++
        if(Igniter.Project.Deps.has_dep?(igniter, :ash), do: ["Claude.Plugins.Ash"], else: []) ++
        if(Igniter.Project.Deps.has_dep?(igniter, :credo), do: ["Claude.Plugins.Credo"], else: []) ++
        if(Igniter.Project.Deps.has_dep?(igniter, :dialyxir),
          do: ["Claude.Plugins.Dialyzer"],
          else: []
        )

    plugins = "[" <> Enum.join(plugins_list, ", ") <> "]"

    """
    %{
      plugins: #{plugins},
      auto_install_deps?: true
    }
    """
  end

  defp install_hooks(igniter) do
    settings_path = Path.join(igniter.assigns.claude_dir_path, "settings.json")
    relative_settings_path = Path.relative_to_cwd(settings_path)

    igniter_with_hooks = read_hooks_from_claude_exs(igniter)
    claude_exs_hooks = igniter_with_hooks.assigns[:claude_exs_hooks] || []

    igniter_with_hooks
    |> install_hooks_to_claude_code_settings(relative_settings_path)
    |> add_hooks_notice(relative_settings_path, claude_exs_hooks)
  end

  defp copy_wrapper_script(igniter) do
    wrapper_source = Path.join(:code.priv_dir(:claude), "claude_hook_wrapper.exs")
    wrapper_dest = Path.join(igniter.assigns.claude_dir_path, "hooks/wrapper.exs")

    if File.exists?(wrapper_source) do
      new_content = File.read!(wrapper_source)

      if Igniter.exists?(igniter, wrapper_dest) do
        igniter
        |> Igniter.update_file(wrapper_dest, fn source ->
          current_content = Rewrite.Source.get(source, :content)

          if current_content == new_content do
            source
          else
            Rewrite.Source.update(source, :content, new_content)
          end
        end)
        |> then(fn updated_igniter ->
          if Igniter.changed?(updated_igniter, wrapper_dest) do
            Igniter.add_notice(
              updated_igniter,
              """
              Claude hook wrapper script updated: #{wrapper_dest}
              This script ensures dependencies are installed before running hooks.
              """
            )
          else
            updated_igniter
          end
        end)
      else
        igniter
        |> Igniter.create_new_file(wrapper_dest, new_content)
        |> Igniter.add_notice("""
        Claude hook wrapper script installed: #{wrapper_dest}
        This script ensures dependencies are installed before running hooks.
        """)
      end
    else
      igniter
    end
  end

  defp add_hooks_notice(igniter, relative_settings_path, hooks) do
    if Igniter.changed?(igniter, relative_settings_path) do
      hooks_message =
        if hooks == [] do
          "No hooks configured in .claude.exs"
        else
          format_hooks_list(hooks)
        end

      igniter
      |> Igniter.add_notice("""
      Claude hooks have been configured in #{relative_settings_path}

      Enabled hooks:
      #{hooks_message}
      """)
    else
      igniter
    end
  end

  defp install_hooks_to_claude_code_settings(igniter, relative_settings_path) do
    initial_settings = build_hooks_settings(%{}, igniter)
    initial_content = Jason.encode!(initial_settings, pretty: true) <> "\n"

    igniter
    |> Igniter.create_or_update_file(relative_settings_path, initial_content, fn source ->
      content = Rewrite.Source.get(source, :content)

      new_content =
        case Jason.decode(content) do
          {:ok, existing_settings} ->
            updated_settings = build_hooks_settings(existing_settings, igniter)
            Jason.encode!(updated_settings, pretty: true) <> "\n"

          {:error, _} ->
            initial_content
        end

      Rewrite.Source.update(source, :content, new_content)
    end)
  end

  defp build_hooks_settings(settings_map, igniter) when is_map(settings_map) do
    cleaned_settings = remove_all_hooks(settings_map)
    all_hooks = igniter.assigns[:claude_exs_hooks] || []
    has_reporters? = igniter.assigns[:has_reporters] || false

    event_types =
      if has_reporters? do
        [
          "PreToolUse",
          "PostToolUse",
          "Stop",
          "SubagentStop",
          "UserPromptSubmit",
          "Notification",
          "PreCompact",
          "SessionStart",
          "SessionEnd"
        ]
      else
        all_hooks
        |> Enum.map(fn {_type, _task, event, _matchers, _desc, _opts} ->
          to_event_type_string(event)
        end)
        |> Enum.uniq()
      end

    if event_types == [] do
      cleaned_settings
    else
      new_hooks =
        event_types
        |> Enum.map(fn event_type ->
          {event_type,
           [
             %{
               "matcher" => "*",
               "hooks" => [
                 %{
                   "type" => "command",
                   "command" =>
                     "cd $CLAUDE_PROJECT_DIR && elixir .claude/hooks/wrapper.exs #{Macro.underscore(event_type)}"
                 }
               ]
             }
           ]}
        end)
        |> Map.new()

      Map.put(cleaned_settings, "hooks", new_hooks)
    end
  end

  defp remove_all_hooks(settings) when is_map(settings) do
    hooks = Map.get(settings, "hooks", %{})
    updated_hooks = remove_old_claude_hooks(hooks)

    if updated_hooks == %{} do
      Map.delete(settings, "hooks")
    else
      Map.put(settings, "hooks", updated_hooks)
    end
  end

  defp remove_old_claude_hooks(hooks_config) do
    claude_patterns = [
      "mix claude hooks run",
      ".claude/hooks/elixir_formatter.exs",
      ".claude/hooks/compilation_checker.exs",
      ".claude/hooks/pre_commit_check.exs",
      ~r{\.claude/hooks/.*\.exs$}
    ]

    hooks_config
    |> Enum.map(fn
      {event_type, matchers} when is_list(matchers) ->
        updated_matchers =
          matchers
          |> Enum.map(fn matcher_obj ->
            hooks_list = Map.get(matcher_obj, "hooks", [])

            filtered_hooks =
              hooks_list
              |> Enum.reject(fn hook ->
                command = Map.get(hook, "command", "")

                Enum.any?(claude_patterns, fn pattern ->
                  case pattern do
                    %Regex{} -> Regex.match?(pattern, command)
                    string -> String.contains?(command, string)
                  end
                end)
              end)

            if filtered_hooks == [] do
              :remove
            else
              Map.put(matcher_obj, "hooks", filtered_hooks)
            end
          end)
          |> Enum.reject(&(&1 == :remove))

        if updated_matchers == [] do
          {event_type, :remove}
        else
          {event_type, updated_matchers}
        end

      {event_type, other} ->
        {event_type, other}
    end)
    |> Enum.reject(fn {_, value} -> value == :remove end)
    |> Map.new()
  end

  defp to_event_type_string(event_atom) do
    case event_atom do
      :pre_tool_use -> "PreToolUse"
      :post_tool_use -> "PostToolUse"
      :user_prompt_submit -> "UserPromptSubmit"
      :notification -> "Notification"
      :stop -> "Stop"
      :subagent_stop -> "SubagentStop"
      :pre_compact -> "PreCompact"
      :session_start -> "SessionStart"
      :session_end -> "SessionEnd"
      _ -> Atom.to_string(event_atom)
    end
  end

  defp format_matcher(nil), do: "*"
  defp format_matcher(".*"), do: "*"
  defp format_matcher(matcher) when is_binary(matcher), do: matcher

  defp format_matcher(matchers) when is_list(matchers) do
    matchers
    |> Enum.map(&matcher_atom_to_string/1)
    |> Enum.join("|")
  end

  defp format_matcher(matcher), do: to_string(matcher)

  defp matcher_atom_to_string(atom) when is_atom(atom) do
    case atom do
      :write -> "Write"
      :edit -> "Edit"
      :multi_edit -> "MultiEdit"
      :bash -> "Bash"
      :glob -> "Glob"
      :grep -> "Grep"
      :read -> "Read"
      :ls -> "LS"
      :task -> "Task"
      :todo_write -> "TodoWrite"
      :web_fetch -> "WebFetch"
      :web_search -> "WebSearch"
      :notebook_edit -> "NotebookEdit"
      :notebook_read -> "NotebookRead"
      :exit_plan_mode -> "ExitPlanMode"
      _ -> atom |> Atom.to_string() |> Macro.camelize()
    end
  end

  defp matcher_atom_to_string(string) when is_binary(string), do: string

  defp format_hooks_list(custom_hooks) do
    custom_hooks
    |> Enum.group_by(fn {_module, _script, _event, _matchers, desc, _opts} ->
      desc
      |> String.replace(~r/ for .+$/, "")
      |> String.replace(~r/ \(.*\)$/, "")
    end)
    |> Enum.map(fn {base_desc, hooks} ->
      events =
        hooks
        |> Enum.map(fn {_module, _script, event, matcher, _desc, _opts} ->
          event_str = format_event_name(event)

          case matcher do
            "*" -> event_str
            ".*" -> event_str
            matcher when is_binary(matcher) -> "#{event_str} (#{matcher})"
            _ -> event_str
          end
        end)
        |> Enum.uniq()
        |> Enum.sort()
        |> Enum.join(", ")

      "  • #{base_desc} → #{events}"
    end)
    |> Enum.sort()
    |> Enum.join("\n")
    |> case do
      "" -> "  No hooks installed"
      hooks -> hooks
    end
  end

  defp format_event_name(event) do
    case event do
      :stop -> "Stop"
      :subagent_stop -> "SubagentStop"
      :post_tool_use -> "PostToolUse"
      :pre_tool_use -> "PreToolUse"
      :user_prompt_submit -> "UserPromptSubmit"
      :notification -> "Notification"
      :pre_compact -> "PreCompact"
      :session_start -> "SessionStart"
      :session_end -> "SessionEnd"
      other -> other |> Atom.to_string() |> Macro.camelize()
    end
  end

  defp sync_usage_rules(igniter) do
    show_notice = !Igniter.exists?(igniter, "CLAUDE.md")
    inline_rules = get_inline_usage_rules(igniter)

    base_args = [
      "CLAUDE.md",
      "--all",
      "--link-to-folder",
      "deps"
    ]

    args =
      if inline_rules == [] do
        base_args
      else
        base_args ++ ["--inline", Enum.join(inline_rules, ",")]
      end

    igniter
    |> Igniter.add_task("usage_rules.sync", args)
    |> then(fn igniter_with_task ->
      if show_notice do
        igniter_with_task
        |> Igniter.add_notice("""
        Syncing usage rules to CLAUDE.md...

        This will help Claude Code understand how to use your project's dependencies.
        """)
      else
        igniter_with_task
      end
    end)
  end

  defp get_inline_usage_rules(igniter) do
    claude_exs_path = igniter.assigns[:claude_exs_path]

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_config_with_plugins(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          Map.get(config, :inline_usage_rules, [])

        _ ->
          []
      end
    else
      []
    end
  end

  defp generate_nested_memories(igniter) do
    Claude.NestedMemories.generate(igniter)
  end

  defp generate_subagents(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_config_with_plugins(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          subagents = Map.get(config, :subagents, [])

          if is_list(subagents) and subagents != [] do
            process_subagents_directly(igniter, subagents)
          else
            igniter
          end

        {:ok, _} ->
          igniter

        {:error, reason} ->
          igniter
          |> Igniter.add_warning("Failed to load .claude.exs: #{reason}")
      end
    else
      igniter
    end
  end

  defp process_subagents_directly(igniter, subagent_configs) do
    results =
      Enum.map(subagent_configs, fn config ->
        case validate_and_generate_subagent(config) do
          {:ok, {name, path, content}} ->
            {:ok, {name, path, content, config}}

          {:error, reason} ->
            {:error, {config[:name] || "Unknown", reason}}
        end
      end)

    errors = Enum.filter(results, &match?({:error, _}, &1))

    if errors == [] do
      successful = Enum.map(results, fn {:ok, result} -> result end)

      {updated_igniter, changed_files} = add_generated_files_with_tracking(igniter, successful)

      final_igniter = add_usage_rules_to_subagents(updated_igniter, successful)

      if changed_files != [] do
        final_igniter
        |> Igniter.add_notice(format_subagents_success_message(changed_files))
      else
        final_igniter
      end
    else
      igniter
      |> Igniter.add_warning(format_subagents_error_message(errors))
    end
  end

  defp validate_and_generate_subagent(config) do
    with :ok <- validate_subagent_config(config),
         {:ok, enhanced_prompt} <- maybe_add_usage_rules(config),
         {:ok, final_prompt} <- maybe_add_memories_using_claude_md_logic(enhanced_prompt, config) do
      name = config.name
      filename = subagent_filename(name)
      relative_path = Path.join([".claude", "agents", filename])

      content =
        generate_subagent_markdown(%{
          name: name,
          description: config.description,
          prompt: final_prompt,
          tools: config[:tools] || []
        })

      {:ok, {name, relative_path, content}}
    end
  end

  defp validate_subagent_config(config) do
    required_keys = [:name, :description, :prompt]
    missing_keys = required_keys -- Map.keys(config)

    if missing_keys == [] do
      with :ok <- validate_tools(config[:tools]),
           :ok <- validate_nested_memories(config[:nested_memories]),
           :ok <- validate_memories(config[:memories]) do
        :ok
      end
    else
      {:error, "Missing required keys: #{inspect(missing_keys)}"}
    end
  end

  defp validate_tools(nil), do: :ok

  defp validate_tools(tools) when is_list(tools) do
    if Enum.all?(tools, &is_atom/1) do
      :ok
    else
      {:error, "Tools must be a list of atoms"}
    end
  end

  defp validate_tools(_), do: {:error, "Tools must be a list"}

  defp validate_nested_memories(nil), do: :ok

  defp validate_nested_memories(memories) when is_list(memories) do
    valid_memory? = fn
      {:url, _} -> true
      {:url, _, _} -> true
      {:file, _} -> true
      {:file, _, _} -> true
      item when is_atom(item) or is_binary(item) -> true
      _ -> false
    end

    if Enum.all?(memories, valid_memory?) do
      :ok
    else
      {:error,
       "nested_memories must use CLAUDE.md nested memory format: strings, atoms, {:url, url} or {:url, url, opts}"}
    end
  end

  defp validate_nested_memories(_), do: {:error, "nested_memories must be a list"}

  defp validate_memories(nil), do: :ok

  defp validate_memories(memories) when is_list(memories) do
    valid_memory? = fn
      {:url, _} -> true
      {:url, _, _} -> true
      {:file, _} -> true
      {:file, _, _} -> true
      item when is_atom(item) or is_binary(item) -> true
      _ -> false
    end

    if Enum.all?(memories, valid_memory?) do
      :ok
    else
      {:error,
       "memories must use CLAUDE.md nested memory format: strings, atoms, {:url, url} or {:url, url, opts}"}
    end
  end

  defp validate_memories(_), do: {:error, "memories must be a list"}

  defp maybe_add_usage_rules(config) do
    case config[:usage_rules] do
      nil ->
        {:ok, config.prompt}

      rules when is_list(rules) ->
        {:ok, config.prompt}

      _ ->
        {:error, "usage_rules must be a list"}
    end
  end

  defp maybe_add_memories_using_claude_md_logic(prompt, config) do
    memories = config[:nested_memories] || config[:memories]

    case memories do
      nil ->
        {:ok, prompt}

      memories when is_list(memories) ->
        case process_memories_using_claude_md_logic(memories) do
          {:ok, processed_content} ->
            if processed_content == "" do
              {:ok, prompt}
            else
              enhanced_prompt = prompt <> "\n\n## Additional Context\n\n" <> processed_content
              {:ok, enhanced_prompt}
            end

          {:error, reason} ->
            {:error, reason}
        end

      _ ->
        {:error, "memories/nested_memories must be a list"}
    end
  end

  defp process_memories_using_claude_md_logic(memories) do
    try do
      {_rules, docs} = partition_memory_items_for_subagent(memories)

      rules_content = ""

      docs_content =
        if docs != [] do
          Claude.Documentation.process_references("", docs)
        else
          ""
        end

      combined_content =
        [rules_content, docs_content]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("\n\n")

      {:ok, combined_content}
    rescue
      error ->
        {:error, "Failed to process memories: #{Exception.message(error)}"}
    end
  end

  defp partition_memory_items_for_subagent(items) do
    Enum.split_with(items, fn
      {:url, _} -> false
      {:url, _, _} -> false
      {:file, _} -> false
      {:file, _, _} -> false
      item when is_atom(item) or is_binary(item) -> true
      _ -> false
    end)
  end

  defp subagent_filename(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> Kernel.<>(".md")
  end

  defp generate_subagent_markdown(subagent) do
    frontmatter = generate_frontmatter(subagent)

    """
    #{frontmatter}

    #{subagent.prompt}
    """
    |> String.trim()
    |> Kernel.<>("\n")
  end

  defp generate_frontmatter(subagent) do
    name =
      subagent.name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    lines = [
      "---",
      "name: #{name}",
      "description: #{subagent.description}"
    ]

    lines =
      if subagent.tools != [] do
        tools_line =
          subagent.tools
          |> Enum.map(&tool_to_string/1)
          |> Enum.join(", ")

        lines ++ ["tools: #{tools_line}"]
      else
        lines
      end

    (lines ++ ["---"])
    |> Enum.join("\n")
  end

  defp add_generated_files_with_tracking(igniter, results) do
    {final_igniter, changed_files} =
      Enum.reduce(results, {igniter, []}, fn {_name, relative_path, content, _config} = result,
                                             {acc, changed} ->
        case Rewrite.source(acc.rewrite, relative_path) do
          {:ok, existing_source} ->
            existing_content = Rewrite.Source.get(existing_source, :content)

            if existing_content == content do
              {acc, changed}
            else
              updated =
                Igniter.update_file(acc, relative_path, fn source ->
                  Rewrite.Source.update(source, :content, content)
                end)

              {updated, [result | changed]}
            end

          {:error, _} ->
            if File.exists?(relative_path) do
              {:ok, existing_content} = File.read(relative_path)

              if existing_content == content do
                included = Igniter.include_existing_file(acc, relative_path)
                {included, changed}
              else
                updated =
                  Igniter.create_or_update_file(acc, relative_path, content, fn source ->
                    Rewrite.Source.update(source, :content, content)
                  end)

                {updated, [result | changed]}
              end
            else
              created = Igniter.create_new_file(acc, relative_path, content)
              {created, [result | changed]}
            end
        end
      end)

    {final_igniter, Enum.reverse(changed_files)}
  end

  defp add_usage_rules_to_subagents(igniter, results) do
    Enum.reduce(results, igniter, fn {_name, relative_path, _content, config}, acc ->
      case config[:usage_rules] do
        rules when is_list(rules) and rules != [] ->
          rule_strings =
            Enum.map(rules, fn
              rule when is_atom(rule) -> Atom.to_string(rule)
              rule when is_binary(rule) -> rule
            end)

          args =
            [relative_path] ++
              rule_strings ++ ["--link-to-folder", "deps", "--link-style", "at", "--yes"]

          Igniter.compose_task(acc, "usage_rules.sync", args)

        _ ->
          acc
      end
    end)
  end

  defp format_subagents_success_message(results) do
    lines = [
      "Generated #{length(results)} subagent(s):",
      ""
    ]

    result_lines =
      Enum.map(results, fn {name, relative_path, _content, _config} ->
        "• #{name} → #{relative_path}"
      end)

    (lines ++ result_lines ++ ["", "Subagents are now available in Claude Code."])
    |> Enum.join("\n")
  end

  defp format_subagents_error_message(errors) do
    error_lines =
      Enum.map(errors, fn {:error, {name, reason}} ->
        "• #{name}: #{inspect(reason)}"
      end)

    (["Failed to generate some subagents:"] ++ error_lines)
    |> Enum.join("\n")
  end

  defp install_commands(igniter) do
    Claude.CommandInstaller.install(igniter)
  end

  defp setup_tidewave_if_configured(igniter) do
    case get_mcp_servers_config(igniter) do
      {:ok, servers} when servers != [] ->
        igniter
        |> Config.write_mcp_config(servers)
        |> add_mcp_notices(servers)

      _ ->
        igniter
    end
  end

  defp get_mcp_servers_config(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_config_with_plugins(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          case Map.get(config, :mcp_servers, []) do
            servers when is_list(servers) ->
              {:ok, servers}

            _ ->
              {:error, "Invalid mcp_servers configuration"}
          end

        {:ok, _} ->
          {:error, "Configuration must be a map"}

        error ->
          error
      end
    else
      {:ok, []}
    end
  end

  defp add_mcp_notices(igniter, servers) do
    notices =
      servers
      |> Enum.filter(fn
        {:tidewave, opts} -> Keyword.get(opts, :enabled?, true) && Keyword.has_key?(opts, :port)
        _ -> false
      end)
      |> Enum.map(fn
        {:tidewave, opts} ->
          port = Keyword.get(opts, :port)

          """
          Tidewave MCP server has been configured in .mcp.json
          URL: http://localhost:#{port}/tidewave/mcp
          """
      end)

    Enum.reduce(notices, igniter, fn notice, acc ->
      Igniter.add_notice(acc, notice)
    end)
  end

  defp read_config_with_plugins(igniter, path) do
    case read_and_eval_claude_exs(igniter, path) do
      {:ok, base_config} when is_map(base_config) ->
        apply_plugins_to_config(igniter, base_config)

      error ->
        error
    end
  end

  defp apply_plugins_to_config(igniter, base_config) do
    case Map.get(base_config, :plugins, []) do
      [] ->
        {:ok, Map.delete(base_config, :plugins)}

      plugins when is_list(plugins) ->
        plugins_with_igniter =
          Enum.map(plugins, fn
            {module, opts} when is_list(opts) -> {module, Keyword.put(opts, :igniter, igniter)}
            module when is_atom(module) -> {module, [igniter: igniter]}
          end)

        case Claude.Plugin.load_plugins(plugins_with_igniter) do
          {:ok, plugin_configs} ->
            final_config =
              (plugin_configs ++ [base_config])
              |> Claude.Plugin.merge_configs()
              |> Map.delete(:plugins)

            {:ok, final_config}

          {:error, _errors} ->
            {:ok, Map.delete(base_config, :plugins)}
        end

      _plugins ->
        {:ok, Map.delete(base_config, :plugins)}
    end
  end

  defp read_and_eval_claude_exs(igniter, path) do
    try do
      source =
        case Rewrite.source(igniter.rewrite, path) do
          {:ok, source} ->
            source

          {:error, _} ->
            igniter = Igniter.include_existing_file(igniter, path)
            Rewrite.source!(igniter.rewrite, path)
        end

      content = Rewrite.Source.get(source, :content)

      {result, _binding} = Code.eval_string(content, [], file: path)
      {:ok, result}
    rescue
      _e in [Rewrite.Error] ->
        {:error, "File not found: #{path}"}

      e in [CompileError, SyntaxError] ->
        {:error, inspect(e)}
    end
  end

  defp check_meta_agent_and_notify(igniter, _path) do
    igniter
  end

  defp tool_to_string(tool) when is_atom(tool) do
    Map.get(@tool_atom_to_string, tool, Atom.to_string(tool))
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false
end
