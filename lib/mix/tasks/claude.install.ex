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

  @meta_agent_config %{
    name: "Meta Agent",
    description: "Generates new, complete Claude Code subagent from user descriptions. Use PROACTIVELY when users ask to create new subagents. Expert agent architect.",
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
          prompt: \"""
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
          \""",
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

  @default_tidewave_port 4000
  @tidewave_setup_instructions """
  Tidewave integrates with your Phoenix application:
  1. Add to your deps in mix.exs: {:tidewave, "~> 0.2.0"}
  2. Run: mix deps.get
  3. Configure in config/dev.exs (see Tidewave docs)
  4. Start your Phoenix server: mix phx.server
  5. MCP endpoint will be at: http://localhost:PORT/tidewave/mcp
  """

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

  @available_hooks [
    {
      Claude.Hooks.PostToolUse.ElixirFormatter,
      ".claude/hooks/elixir_formatter.exs",
      :post_tool_use,
      ["Edit", "Write", "MultiEdit"],
      "Automatically formats Elixir files after editing"
    },
    {
      Claude.Hooks.PostToolUse.CompilationChecker,
      ".claude/hooks/compilation_checker.exs",
      :post_tool_use,
      ["Edit", "Write", "MultiEdit"],
      "Checks for compilation errors after editing Elixir files"
    },
    {
      Claude.Hooks.PreToolUse.PreCommitCheck,
      ".claude/hooks/pre_commit_check.exs",
      :pre_tool_use,
      ["Bash"],
      "Validates code before git commits"
    }
  ]

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
    |> setup_phoenix_mcp()
    |> sync_usage_rules()
    |> generate_subagents()
    |> setup_tidewave_if_configured()
  end

  defp create_claude_exs(igniter) do
    path = igniter.assigns[:claude_exs_path]

    if Igniter.exists?(igniter, path) do
      # If .claude.exs exists, just check if Meta Agent is missing and notify
      check_meta_agent_and_notify(igniter, path)
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
      {:usage_rules, "~> 0.1", only: [:dev]},
      on_exists: :skip
    )
  end

  defp format_meta_agent_for_template do
    # Format the Meta Agent config for inclusion in the template
    inspect(@meta_agent_config, pretty: true, limit: :infinity, printable_limit: :infinity)
  end
  
  defp format_meta_agent_for_notice do
    # Format the Meta Agent config for display in notices
    # Build it manually to show proper formatting
    name = inspect(@meta_agent_config.name)
    description = inspect(@meta_agent_config.description)
    tools = inspect(@meta_agent_config.tools)
    prompt = @meta_agent_config.prompt
    
    # Manually build the string to preserve formatting
    "    %{\n" <>
    "      name: #{name},\n" <>
    "      description: #{description},\n" <>
    "      prompt: \"\"\"\n#{prompt}\"\"\",\n" <>
    "      tools: #{tools}\n" <>
    "    }"
  end

  defp claude_exs_template do
    meta_agent_str = format_meta_agent_for_template()
    
    """
    # .claude.exs - Claude configuration for this project
    # This file is evaluated when Claude reads your project settings
    # and merged with .claude/settings.json (this file takes precedence)

    # You can configure various aspects of Claude's behavior here:
    # - Project metadata and context
    # - Custom behaviors and preferences
    # - Development workflow settings
    # - Code generation patterns
    # - And more as Claude evolves

    # Example configuration (uncomment and modify as needed):
    %{
      # Custom hooks can be registered here
      # hooks: [
      #   MyProject.Hooks.CustomFormatter,
      #   MyProject.Hooks.SecurityChecker
      # ],

      # MCP servers (Tidewave is automatically configured for Phoenix projects)
      # mcp_servers: [:tidewave],
      #
      # You can also specify custom configuration like port:
      # mcp_servers: [
      #   {:tidewave, [port: 5000]}
      # ],
      #
      # To disable a server without removing it:
      # mcp_servers: [
      #   {:tidewave, [port: 4000, enabled?: false]}
      # ],

      # Subagents provide specialized expertise with their own context
      subagents: [
        #{meta_agent_str}
      ]
    }
    """
  end

  defp install_hooks(igniter) do
    settings_path = Path.join(igniter.assigns.claude_dir_path, "settings.json")
    relative_settings_path = Path.relative_to_cwd(settings_path)

    igniter
    |> install_hooks_claude_code_hooks_dir()
    |> install_hooks_to_claude_code_settings(relative_settings_path)
    |> Igniter.add_notice("""
    Claude hooks have been installed to #{relative_settings_path}
    Hook scripts generated in .claude/hooks/

    Enabled hooks:
    #{format_hooks_list()}
    """)
  end

  defp install_hooks_to_claude_code_settings(igniter, relative_settings_path) do
    initial_settings = build_hooks_settings(%{})
    initial_content = Jason.encode!(initial_settings, pretty: true) <> "\n"

    igniter
    |> Igniter.create_or_update_file(relative_settings_path, initial_content, fn source ->
      content = Rewrite.Source.get(source, :content)

      new_content =
        case Jason.decode(content) do
          {:ok, existing_settings} ->
            updated_settings = build_hooks_settings(existing_settings)
            Jason.encode!(updated_settings, pretty: true) <> "\n"

          {:error, _} ->
            initial_content
        end

      Rewrite.Source.update(source, :content, new_content)
    end)
  end

  defp build_hooks_settings(settings_map) when is_map(settings_map) do
    cleaned_settings = remove_all_hooks(settings_map)
    cleaned_hooks = Map.get(cleaned_settings, "hooks", %{})

    hooks_by_event_and_matcher =
      @available_hooks
      |> Enum.group_by(fn {_module, _script, event, matchers, _desc} ->
        event_type = to_event_type_string(event)
        matcher = format_matcher(matchers)
        {event_type, matcher}
      end)

    new_hooks =
      Enum.reduce(hooks_by_event_and_matcher, cleaned_hooks, fn {{event_type, matcher}, hooks},
                                                                acc ->
        existing_matchers = Map.get(acc, event_type, [])

        matcher_index =
          Enum.find_index(existing_matchers, fn m ->
            Map.get(m, "matcher") == matcher
          end)

        hook_configs =
          Enum.map(hooks, fn {_module, script_path, _event, _matchers, _desc} ->
            %{
              "type" => "command",
              "command" => "cd $CLAUDE_PROJECT_DIR && elixir #{script_path}"
            }
          end)

        if matcher_index do
          updated_matchers =
            List.update_at(existing_matchers, matcher_index, fn matcher_obj ->
              existing_hooks = Map.get(matcher_obj, "hooks", [])
              Map.put(matcher_obj, "hooks", existing_hooks ++ hook_configs)
            end)

          Map.put(acc, event_type, updated_matchers)
        else
          new_matcher_obj = %{
            "matcher" => matcher,
            "hooks" => hook_configs
          }

          Map.put(acc, event_type, existing_matchers ++ [new_matcher_obj])
        end
      end)

    Map.put(settings_map, "hooks", new_hooks)
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
      ".claude/hooks/pre_commit_check.exs"
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
                Enum.any?(claude_patterns, &String.contains?(command, &1))
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
      _ -> Atom.to_string(event_atom)
    end
  end

  defp format_matcher(nil), do: "*"
  defp format_matcher(".*"), do: "*"
  defp format_matcher(matcher) when is_binary(matcher), do: matcher

  defp format_matcher(matchers) when is_list(matchers) do
    matchers
    |> Enum.map(&to_string/1)
    |> Enum.join("|")
  end

  defp format_matcher(matcher), do: to_string(matcher)

  defp format_hooks_list do
    @available_hooks
    |> Enum.map(fn {_module, _script, _event, _matchers, desc} ->
      "  • #{desc}"
    end)
    |> Enum.join("\n")
    |> case do
      "" -> "  No hooks installed"
      hooks -> hooks
    end
  end

  defp install_hooks_claude_code_hooks_dir(igniter) do
    claude_dep = get_claude_dependency()

    Enum.reduce(@available_hooks, igniter, fn {module, script_path, _event, _matchers, _desc},
                                              acc ->
      content = generate_hook_script(module, claude_dep)

      Igniter.create_or_update_file(acc, script_path, content, fn source ->
        Rewrite.Source.update(source, :content, content)
      end)
    end)
  end

  defp generate_hook_script(hook_module, claude_dep) do
    module_name = Module.split(hook_module) |> Enum.join(".")

    deps = "[#{claude_dep}, {:jason, \"~> 1.4\"}]"

    description =
      if function_exported?(hook_module, :description, 0) do
        hook_module.description()
      else
        "Claude Code hook"
      end

    """
    #!/usr/bin/env elixir
    # Hook script for #{description}
    # This script is called with JSON input via stdin from Claude Code

    # Install dependencies
    Mix.install(#{deps})

    # Read JSON from stdin
    input = IO.read(:stdio, :eof)

    # Reuse the existing hook module
    case #{module_name}.run(input) do
      :ok -> System.halt(0)
      _ -> System.halt(1)
    end
    """
  end

  defp get_claude_dependency do
    if Mix.Project.get() == Claude.MixProject do
      "{:claude, path: \".\"}"
    else
      case get_claude_version_from_deps() do
        {:ok, version} -> "{:claude, \"#{version}\"}"
        :error -> "{:claude, \"~> 0.1\"}"
      end
    end
  end

  defp get_claude_version_from_deps do
    case get_installed_claude_version() do
      {:ok, version} ->
        {:ok, "~> #{version}"}

      :error ->
        deps = Mix.Project.config()[:deps] || []

        case List.keyfind(deps, :claude, 0) do
          {:claude, version} when is_binary(version) ->
            {:ok, version}

          {:claude, version, _opts} when is_binary(version) ->
            {:ok, version}

          _ ->
            :error
        end
    end
  end

  defp get_installed_claude_version do
    case Mix.Project.deps_paths() do
      %{claude: claude_path} when is_binary(claude_path) ->
        mix_file = Path.join(claude_path, "mix.exs")

        with true <- File.exists?(mix_file),
             {:ok, content} <- File.read(mix_file),
             [_, version] <- Regex.run(~r/@version\s+"([^"]+)"/, content) do
          {:ok, version}
        else
          _ -> :error
        end

      _ ->
        :error
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
    igniter
    |> Igniter.add_notice("""
    Phoenix detected! To enable Tidewave MCP server, add the following to your .claude.exs file:

    %{
      mcp_servers: [:tidewave]
    }

    Or with a custom port:

    %{
      mcp_servers: [{:tidewave, [port: 5000]}]
    }

    Tidewave provides Phoenix-specific tools for working with your application.
    """)
  end

  defp sync_usage_rules(igniter) do
    igniter
    |> Igniter.add_notice("""
    Syncing usage rules to CLAUDE.md...

    This will help Claude Code understand how to use your project's dependencies.
    """)
    |> Igniter.add_task("usage_rules.sync", ["CLAUDE.md", "--all", "--link-to-folder", "deps"])
  end

  defp generate_subagents(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_and_eval_claude_exs(igniter, claude_exs_path) do
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

      igniter
      |> add_generated_files(successful)
      |> Igniter.add_notice(format_subagents_success_message(successful))
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
      # Validate tools if present
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
        enhanced_prompt = config.prompt <> "\n\n## Usage Rules\n\n" <> usage_rules_content
        {:ok, enhanced_prompt}

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
    # Look for deps/package_name/usage-rules.md
    path = Path.join(["deps", Atom.to_string(rule), "usage-rules.md"])

    case File.read(path) do
      {:ok, content} -> "### #{rule}\n\n#{content}"
      _ -> nil
    end
  end

  defp load_single_usage_rule(rule) when is_binary(rule) do
    case String.split(rule, ":", parts: 2) do
      [package] ->
        # Same as atom version
        load_single_usage_rule(String.to_atom(package))

      [package, "all"] ->
        # Load all usage-rules files in the package
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
        # Load specific sub-rule
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
  end

  defp generate_frontmatter(subagent) do
    # Convert name to lowercase with hyphens as per Claude Code conventions
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

  defp add_generated_files(igniter, results) do
    Enum.reduce(results, igniter, fn {_name, relative_path, content}, acc ->
      Igniter.create_or_update_file(acc, relative_path, content, fn source ->
        Rewrite.Source.update(source, :content, content)
      end)
    end)
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

  defp setup_tidewave_if_configured(igniter) do
    relative_settings_path = Path.join(igniter.assigns.claude_dir_path, "settings.json")

    case get_tidewave_config(igniter) do
      {:ok, port} ->
        igniter
        |> update_settings_with_tidewave(relative_settings_path, port)
        |> Igniter.add_notice("""
        Tidewave MCP server has been configured in #{relative_settings_path}

        Port: #{port}
        Endpoint: http://localhost:#{port}/tidewave/mcp

        #{@tidewave_setup_instructions}
        """)

      :not_configured ->
        igniter

      :disabled ->
        igniter
        |> remove_tidewave_from_settings(relative_settings_path)
    end
  end

  defp get_tidewave_config(igniter) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      case read_and_eval_claude_exs(igniter, claude_exs_path) do
        {:ok, config} when is_map(config) ->
          case Map.get(config, :mcp_servers, []) do
            [] ->
              :not_configured

            servers when is_list(servers) ->
              case find_tidewave_in_servers(servers) do
                {:ok, port} -> {:ok, port}
                :disabled -> :disabled
                :not_found -> :not_configured
              end

            _ ->
              :not_configured
          end

        _ ->
          :not_configured
      end
    else
      :not_configured
    end
  end

  defp read_and_eval_claude_exs(igniter, path) do
    try do
      igniter = Igniter.include_existing_file(igniter, path)
      source = Rewrite.source!(igniter.rewrite, path)
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

  defp find_tidewave_in_servers([]), do: :not_found
  defp find_tidewave_in_servers([:tidewave | _]), do: {:ok, @default_tidewave_port}

  defp find_tidewave_in_servers([{:tidewave, opts} | _]) when is_list(opts) do
    if Keyword.get(opts, :enabled?, true) do
      port = Keyword.get(opts, :port, @default_tidewave_port)
      {:ok, port}
    else
      :disabled
    end
  end

  defp find_tidewave_in_servers([_ | rest]), do: find_tidewave_in_servers(rest)

  defp update_settings_with_tidewave(igniter, relative_settings_path, port) do
    initial_settings = %{}
    initial_content = Jason.encode!(initial_settings, pretty: true) <> "\n"

    igniter
    |> Igniter.create_or_update_file(relative_settings_path, initial_content, fn source ->
      content = Rewrite.Source.get(source, :content)

      new_content =
        case Jason.decode(content) do
          {:ok, settings} ->
            tidewave_config = %{
              "tidewave" => %{
                "type" => "sse",
                "url" => "http://localhost:#{port}/tidewave/mcp"
              }
            }

            updated_settings = Map.put(settings, "mcpServers", tidewave_config)
            Jason.encode!(updated_settings, pretty: true) <> "\n"

          {:error, _} ->
            settings = %{
              "mcpServers" => %{
                "tidewave" => %{
                  "type" => "sse",
                  "url" => "http://localhost:#{port}/tidewave/mcp"
                }
              }
            }

            Jason.encode!(settings, pretty: true) <> "\n"
        end

      Rewrite.Source.update(source, :content, new_content)
    end)
  end

  defp remove_tidewave_from_settings(igniter, relative_settings_path) do
    if Igniter.exists?(igniter, relative_settings_path) do
      igniter
      |> Igniter.update_file(relative_settings_path, fn source ->
        content = Rewrite.Source.get(source, :content)

        case Jason.decode(content) do
          {:ok, settings} ->
            case Map.get(settings, "mcpServers") do
              %{"tidewave" => _} = mcp_servers ->
                updated_mcp = Map.delete(mcp_servers, "tidewave")

                updated_settings =
                  if map_size(updated_mcp) == 0 do
                    Map.delete(settings, "mcpServers")
                  else
                    Map.put(settings, "mcpServers", updated_mcp)
                  end

                new_content = Jason.encode!(updated_settings, pretty: true) <> "\n"
                Rewrite.Source.update(source, :content, new_content)

              _ ->
                source
            end

          {:error, _} ->
            source
        end
      end)
    else
      igniter
    end
  end

  defp check_meta_agent_and_notify(igniter, path) do
    # Skip in test environment
    if igniter.assigns[:test_mode] || Mix.env() == :test do
      igniter
    else
      case read_and_eval_claude_exs(igniter, path) do
        {:ok, config} when is_map(config) ->
          subagents = Map.get(config, :subagents, [])
          
          has_meta_agent = Enum.any?(subagents, fn agent ->
            Map.get(agent, :name) == "Meta Agent"
          end)
          
          if has_meta_agent do
            igniter
          else
            # Show notice about how to add Meta Agent
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
          # If we can't read the file, just return the igniter unchanged
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
