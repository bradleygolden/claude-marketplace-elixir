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
  @tidewave_version "~> 0.2"

  @meta_agent_config %{
    name: "Meta Agent",
    description:
      "Generates new, complete Claude Code subagent from user descriptions. Use PROACTIVELY when users ask to create new subagents. Expert agent architect.",
    prompt: """
    # Purpose

    Your sole purpose is to act as an expert agent architect. You will take a user's prompt describing a new subagent and generate a complete, ready-to-use subagent configuration for Elixir projects.

    ## Important Documentation

    You MUST reference these official Claude Code documentation pages to ensure accurate subagent generation:
    - **Subagents Guide**: https://docs.anthropic.com/en/docs/claude-code/sub-agents
    - **Settings Reference**: https://docs.anthropic.com/en/docs/claude-code/settings
    - **Hooks System**: https://docs.anthropic.com/en/docs/claude-code/hooks

    Use the WebSearch tool to look up specific details from these docs when needed, especially for:
    - Tool naming conventions and available tools
    - Subagent YAML frontmatter format
    - Best practices for descriptions and delegation
    - Settings.json structure and configuration options

    ## Instructions

    When invoked, you must follow these steps:

    1. **Analyze Input:** Carefully analyze the user's request to understand the new agent's purpose, primary tasks, and domain
       - Use WebSearch to consult the subagents documentation if you need clarification on best practices

    2. **Devise a Name:** Create a descriptive name (e.g., "Database Migration Agent", "API Integration Agent")

    3. **Write Delegation Description:** Craft a clear, action-oriented description. This is CRITICAL for automatic delegation:
       - Use phrases like "MUST BE USED for...", "Use PROACTIVELY when...", "Expert in..."
       - Be specific about WHEN to invoke
       - Avoid overlap with existing agents

    4. **Infer Necessary Tools:** Based on tasks, determine MINIMAL tools required:
       - Code reviewer: `[:read, :grep, :glob]`
       - Refactorer: `[:read, :edit, :multi_edit, :grep]`
       - Test runner: `[:read, :edit, :bash, :grep]`
       - Remember: No `:task` prevents delegation loops

    5. **Construct System Prompt:** Design the prompt considering:
       - **Clean Slate**: Agent has NO memory between invocations
       - **Context Discovery**: Specify exact files/patterns to check first
       - **Performance**: Avoid reading entire directories
       - **Self-Contained**: Never assume main chat context

    6. **Check for Issues:**
       - Read current `.claude.exs` to avoid description conflicts
       - Ensure tools match actual needs (no extras)

    7. **Generate Configuration:** Add the new subagent to `.claude.exs`:

        %{
          name: "Generated Name",
          description: "Generated action-oriented description",
          prompt: \\\"""
          # Purpose
          You are [role definition].

          ## Instructions
          When invoked, follow these steps:
          1. [Specific startup sequence]
          2. [Core task execution]
          3. [Validation/verification]

          ## Context Discovery
          Since you start fresh each time:
          - Check: [specific files first]
          - Pattern: [efficient search patterns]
          - Limit: [what NOT to read]

          ## Best Practices
          - [Domain-specific guidelines]
          - [Performance considerations]
          - [Common pitfalls to avoid]
          \\\""",
          tools: [inferred tools]
        }

    8. **Final Actions:**
       - Update `.claude.exs` with the new configuration
       - Instruct user to run `mix claude.install`

    ## Key Principles

    **Avoid Common Pitfalls:**
    - Context overflow: "Read all files in lib/" → "Read only specific module"
    - Ambiguous delegation: "Database expert" → "MUST BE USED for Ecto migrations"
    - Hidden dependencies: "Continue refactoring" → "Refactor to [explicit patterns]"
    - Tool bloat: Only include tools actually needed

    **Performance Patterns:**
    - Targeted reads over directory scans
    - Specific grep patterns over broad searches
    - Limited context gathering on startup

    ## Output Format

    Your response should:
    1. Show the complete subagent configuration to add
    2. Explain key design decisions
    3. Warn about any potential conflicts
    4. Remind to run `mix claude.install`
    """,
    tools: [:write, :read, :edit, :multi_edit, :bash, :web_search]
  }

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
    |> setup_phoenix_mcp()
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
      |> check_meta_agent_and_notify(path)
    else
      Igniter.create_new_file(
        igniter,
        path,
        claude_exs_template()
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
    # Used by "mix format"
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

  defp format_meta_agent_for_notice do
    name = inspect(@meta_agent_config.name)
    description = inspect(@meta_agent_config.description)
    tools = inspect(@meta_agent_config.tools)
    prompt = @meta_agent_config.prompt

    "    %{\n" <>
      "      name: #{name},\n" <>
      "      description: #{description},\n" <>
      "      prompt: \"\"\"\n#{prompt}\"\"\",\n" <>
      "      tools: #{tools}\n" <>
      "    }"
  end

  defp claude_exs_template do
    """
    %{
      plugins: [Claude.Plugins.Base],
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
      ".claude/hooks/related_files.exs",
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

  defp setup_phoenix_mcp(igniter) do
    if Igniter.Project.Deps.has_dep?(igniter, :phoenix) do
      add_tidewave_to_project(igniter)
    else
      igniter
    end
  end

  defp add_tidewave_to_project(igniter) do
    igniter =
      igniter
      |> Igniter.Project.Deps.add_dep({:tidewave, @tidewave_version, only: [:dev]},
        on_exists: :skip
      )
      |> Igniter.add_task("tidewave.install")
      |> add_tidewave_to_mcp_servers()

    if Igniter.changed?(igniter, ".claude.exs") || Igniter.changed?(igniter, "mix.exs") do
      igniter
      |> Igniter.add_notice("""
      Phoenix project detected! Automatically adding Tidewave for enhanced Phoenix development.

      Tidewave provides Phoenix-specific MCP tools for Claude Code, including:
      - Route inspection and generation
      - LiveView component assistance
      - Schema and migration tools
      - Context generation helpers
      """)
    else
      igniter
    end
  end

  defp add_tidewave_to_mcp_servers(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_config_with_plugins(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          mcp_servers = Map.get(config, :mcp_servers, [])

          if tidewave_already_configured?(mcp_servers) do
            igniter
          else
            updated_servers = add_tidewave_to_list(mcp_servers)
            updated_config = Map.put(config, :mcp_servers, updated_servers)

            igniter
            |> Igniter.update_file(claude_exs_path, fn source ->
              Rewrite.Source.update(
                source,
                :content,
                inspect(updated_config, pretty: true, limit: :infinity)
              )
            end)
            |> Config.write_mcp_config(updated_servers)
          end

        _ ->
          updated_config = %{mcp_servers: [:tidewave]}

          igniter
          |> Igniter.create_or_update_file(
            claude_exs_path,
            inspect(updated_config, pretty: true, limit: :infinity),
            fn source ->
              Rewrite.Source.update(
                source,
                :content,
                inspect(updated_config, pretty: true, limit: :infinity)
              )
            end
          )
          |> Config.write_mcp_config([:tidewave])
      end
    else
      config = %{mcp_servers: [:tidewave]}

      igniter
      |> Igniter.create_or_update_file(
        claude_exs_path,
        inspect(config, pretty: true, limit: :infinity),
        fn _source -> :error end
      )
      |> Config.write_mcp_config([:tidewave])
    end
  end

  defp tidewave_already_configured?(mcp_servers) when is_list(mcp_servers) do
    Enum.any?(mcp_servers, fn
      :tidewave -> true
      {:tidewave, _} -> true
      _ -> false
    end)
  end

  defp tidewave_already_configured?(_), do: false

  defp add_tidewave_to_list(mcp_servers) when is_list(mcp_servers) do
    [:tidewave | mcp_servers]
  end

  defp add_tidewave_to_list(_), do: [:tidewave]

  defp sync_usage_rules(igniter) do
    # Always show notice on first install (when CLAUDE.md doesn't exist)
    show_notice = !Igniter.exists?(igniter, "CLAUDE.md")

    igniter
    |> Igniter.add_task("usage_rules.sync", [
      "CLAUDE.md",
      "--all",
      "--link-to-folder",
      "deps"
    ])
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
            {:ok, {name, path, content}}

          {:error, reason} ->
            {:error, {config[:name] || "Unknown", reason}}
        end
      end)

    errors = Enum.filter(results, &match?({:error, _}, &1))

    if errors == [] do
      successful = Enum.map(results, fn {:ok, result} -> result end)

      {updated_igniter, changed_files} = add_generated_files_with_tracking(igniter, successful)

      if changed_files != [] do
        updated_igniter
        |> Igniter.add_notice(format_subagents_success_message(changed_files))
      else
        updated_igniter
      end
    else
      igniter
      |> Igniter.add_warning(format_subagents_error_message(errors))
    end
  end

  defp validate_and_generate_subagent(config) do
    with :ok <- validate_subagent_config(config),
         {:ok, enhanced_prompt} <- maybe_add_usage_rules(config) do
      name = config.name
      filename = subagent_filename(name)
      relative_path = Path.join([".claude", "agents", filename])

      content =
        generate_subagent_markdown(%{
          name: name,
          description: config.description,
          prompt: enhanced_prompt,
          tools: config[:tools] || []
        })

      {:ok, {name, relative_path, content}}
    end
  end

  defp validate_subagent_config(config) do
    required_keys = [:name, :description, :prompt]
    missing_keys = required_keys -- Map.keys(config)

    if missing_keys == [] do
      case config[:tools] do
        nil ->
          :ok

        tools when is_list(tools) ->
          if Enum.all?(tools, &is_atom/1) do
            :ok
          else
            {:error, "Tools must be a list of atoms"}
          end

        _ ->
          {:error, "Tools must be a list"}
      end
    else
      {:error, "Missing required keys: #{inspect(missing_keys)}"}
    end
  end

  defp maybe_add_usage_rules(config) do
    case config[:usage_rules] do
      nil ->
        {:ok, config.prompt}

      rules when is_list(rules) ->
        usage_rules_content = load_usage_rules(rules)

        if usage_rules_content == "" do
          {:ok, config.prompt}
        else
          enhanced_prompt = config.prompt <> "\n\n## Usage Rules\n\n" <> usage_rules_content
          {:ok, enhanced_prompt}
        end

      _ ->
        {:error, "usage_rules must be a list"}
    end
  end

  defp load_usage_rules(rules) do
    rules
    |> Enum.map(&load_single_usage_rule/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")
  end

  defp load_single_usage_rule(rule) when is_atom(rule) do
    path = Path.join(["deps", Atom.to_string(rule), "usage-rules.md"])

    case File.read(path) do
      {:ok, content} -> "### #{rule}\n\n#{content}"
      _ -> nil
    end
  end

  defp load_single_usage_rule(rule) when is_binary(rule) do
    case String.split(rule, ":", parts: 2) do
      [package] ->
        load_single_usage_rule(String.to_atom(package))

      [package, "all"] ->
        deps_path = Path.join("deps", package)
        usage_rules_path = Path.join(deps_path, "usage-rules")

        if File.dir?(usage_rules_path) do
          usage_rules_path
          |> File.ls!()
          |> Enum.filter(&String.ends_with?(&1, ".md"))
          |> Enum.map(fn file ->
            path = Path.join(usage_rules_path, file)

            case File.read(path) do
              {:ok, content} -> "### #{package}:#{Path.rootname(file)}\n\n#{content}"
              _ -> nil
            end
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.join("\n\n")
        else
          nil
        end

      [package, sub_rule] ->
        path = Path.join(["deps", package, "usage-rules", "#{sub_rule}.md"])

        case File.read(path) do
          {:ok, content} -> "### #{package}:#{sub_rule}\n\n#{content}"
          _ -> nil
        end
    end
  end

  defp load_single_usage_rule(_), do: nil

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

    # Add tools line only if tools are specified
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
      Enum.reduce(results, {igniter, []}, fn {_name, relative_path, content} = result,
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

  defp format_subagents_success_message(results) do
    lines = [
      "Generated #{length(results)} subagent(s):",
      ""
    ]

    result_lines =
      Enum.map(results, fn {name, relative_path, _content} ->
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

  # Helper function to read config with plugin support
  defp read_config_with_plugins(igniter, path) do
    case read_and_eval_claude_exs(igniter, path) do
      {:ok, base_config} when is_map(base_config) ->
        apply_plugins_to_config(base_config)

      error ->
        error
    end
  end

  # Apply plugins to a config map (similar to Claude.Config but works with any config)
  defp apply_plugins_to_config(base_config) do
    case Map.get(base_config, :plugins, []) do
      [] ->
        {:ok, Map.delete(base_config, :plugins)}

      plugins when is_list(plugins) ->
        case Claude.Plugin.load_plugins(plugins) do
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
    if igniter.assigns[:test_mode] || Mix.env() == :test do
      igniter
    else
      case read_config_with_plugins(igniter, ".claude.exs") do
        {:ok, config} when is_map(config) ->
          subagents = Map.get(config, :subagents, [])

          has_meta_agent =
            Enum.any?(subagents, fn agent ->
              Map.get(agent, :name) == "Meta Agent"
            end)

          if has_meta_agent do
            igniter
          else
            igniter
            |> Igniter.add_notice("""

            Your project doesn't have a Meta Agent configured.
            The Meta Agent helps you create new subagents.

            To add it, copy the following to your .claude.exs subagents list:

            #{format_meta_agent_for_notice()}

            Then run `mix claude.install` again to generate the agent file.
            """)
          end

        _ ->
          igniter
      end
    end
  end

  defp tool_to_string(tool) when is_atom(tool) do
    Map.get(@tool_atom_to_string, tool, Atom.to_string(tool))
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false
end
