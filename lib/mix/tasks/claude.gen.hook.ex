defmodule Mix.Tasks.Claude.Gen.Hook do
  @shortdoc "Generate a new Claude hook module (internal development)"

  @moduledoc """
  Generate a new Claude hook module for internal development of the Claude library.

  > **Note**: This generator is primarily intended for extending the Claude library itself.
  > Due to current limitations with hook module loading in isolated script contexts,
  > custom project hooks may not work as expected. We recommend using the built-in
  > hooks provided by Claude.

  This task creates a new hook module that can be registered in your `.claude.exs` file.

  ## Usage

  ### Interactive Mode

      mix claude.gen.hook

  The task will guide you through selecting the event type, tools, and options.

  ### Non-Interactive Mode

      mix claude.gen.hook MyCustomHook --event post_tool_use --matcher "write,edit" --description "My custom hook"
      
      # Or with a fully-qualified module name
      mix claude.gen.hook MyApp.Hooks.CustomFormatter --event post_tool_use --matcher "write,edit"

  ## Options

    * `--event` - The hook event type. One of:
      * `post_tool_use` - Runs after tool execution
      * `pre_tool_use` - Runs before tool execution
      * `user_prompt_submit` - Runs when user submits a prompt
      * `notification` - Runs when Claude sends notifications
      * `stop` - Runs when Claude finishes responding
      * `subagent_stop` - Runs when a subagent finishes
      * `pre_compact` - Runs before compaction

    * `--matcher` - Tool pattern matcher (for pre_tool_use/post_tool_use events).
      Examples: `"write"`, `"write,edit,multi_edit"`, `"*"` (all tools)
      Use snake_case and comma separation for multiple tools.

    * `--description` - Human-readable description of what the hook does

    * `--add-to-config` - Automatically add the hook to `.claude.exs` (default: true)

  ## Examples

      # Generate a post-tool-use hook for formatting
      mix claude.gen.hook Formatter --event post_tool_use --matcher "write,edit" --description "Format files after editing"

      # Generate a pre-tool-use hook for validation
      mix claude.gen.hook Validator --event pre_tool_use --matcher "bash" --description "Validate bash commands"

      # Generate a notification hook
      mix claude.gen.hook Notifier --event notification --description "Custom notification handler"
      
      # Generate a hook with custom module path
      mix claude.gen.hook MyApp.Security.BashValidator --event pre_tool_use --matcher "bash"

  After generating a hook, remember to run `mix claude.install` to activate it.
  """

  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example:
        "mix claude.gen.hook MyHook --event post_tool_use --matcher write --description \"My hook\"",
      only: [:dev],
      schema: [
        event: :string,
        matcher: :string,
        description: :string,
        add_to_config: :boolean
      ],
      defaults: [
        add_to_config: true
      ],
      positional: [module_name: [optional: true]]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    module_name = igniter.args.positional[:module_name]
    opts = igniter.args.options

    if module_name == nil do
      run_interactive(igniter)
    else
      if opts[:event] == nil do
        run_semi_interactive(igniter, module_name, opts)
      else
        case validate_args(module_name, opts) do
          {:ok, validated_module_name, validated_opts} ->
            igniter
            |> generate_hook_module(validated_module_name, validated_opts)
            |> maybe_add_to_config(validated_module_name, validated_opts)
            |> add_success_notice(validated_module_name, validated_opts)

          {:error, message} ->
            igniter
            |> Igniter.add_issue(message)
        end
      end
    end
  end

  defp run_interactive(igniter) do
    IO.puts("\n🪝 Claude Hook Generator\n")

    with {:ok, module_name} <- prompt_for_module_name(),
         {:ok, event} <- prompt_for_event(),
         {:ok, matcher} <- prompt_for_matcher(event),
         {:ok, description} <- prompt_for_description(),
         {:ok, add_to_config} <- prompt_for_add_to_config() do
      opts = [
        event: event,
        matcher: parse_matcher_input(matcher),
        description: description,
        add_to_config: add_to_config
      ]

      igniter
      |> generate_hook_module(module_name, opts)
      |> maybe_add_to_config(module_name, opts)
      |> add_success_notice(module_name, opts)
    else
      {:error, :cancelled} ->
        igniter
        |> Igniter.add_notice("Hook generation cancelled.")

      {:error, message} ->
        igniter
        |> Igniter.add_issue(message)
    end
  end

  defp run_semi_interactive(igniter, module_name, opts) do
    IO.puts("\n🪝 Claude Hook Generator\n")
    IO.puts("Module: #{module_name}")

    with {:ok, event} <- prompt_for_event(),
         {:ok, matcher} <- prompt_for_matcher(event),
         {:ok, description} <- prompt_for_description_with_default(opts[:description]),
         {:ok, add_to_config} <- prompt_for_add_to_config_with_default(opts[:add_to_config]) do
      validated_opts = [
        event: event,
        matcher: parse_matcher_input(matcher),
        description: description,
        add_to_config: add_to_config
      ]

      igniter
      |> generate_hook_module(module_name, validated_opts)
      |> maybe_add_to_config(module_name, validated_opts)
      |> add_success_notice(module_name, validated_opts)
    else
      {:error, :cancelled} ->
        igniter
        |> Igniter.add_notice("Hook generation cancelled.")

      {:error, message} ->
        igniter
        |> Igniter.add_issue(message)
    end
  end

  defp validate_args(module_name, opts) do
    with {:ok, event} <- validate_event(opts[:event]),
         {:ok, validated_opts} <- validate_opts_for_event(event, opts) do
      {:ok, module_name, validated_opts}
    end
  end

  defp validate_event(nil) do
    {:error,
     """
     Missing required --event option.

     Valid events: post_tool_use, pre_tool_use, user_prompt_submit, notification, stop, subagent_stop, pre_compact
     """}
  end

  defp validate_event(event)
       when event in ~w(post_tool_use pre_tool_use user_prompt_submit notification stop subagent_stop pre_compact) do
    {:ok, String.to_atom(event)}
  end

  defp validate_event(event) do
    {:error,
     """
     Invalid event type: #{event}

     Valid events: post_tool_use, pre_tool_use, user_prompt_submit, notification, stop, subagent_stop, pre_compact
     """}
  end

  defp validate_opts_for_event(event, opts) when event in [:pre_tool_use, :post_tool_use] do
    validated_opts = [
      event: event,
      matcher: parse_matcher_input(opts[:matcher]),
      description: opts[:description] || "Custom #{event} hook",
      add_to_config: opts[:add_to_config]
    ]

    {:ok, validated_opts}
  end

  defp validate_opts_for_event(event, opts) do
    if opts[:matcher] do
      {:error, "The --matcher option is only valid for pre_tool_use and post_tool_use events"}
    else
      validated_opts = [
        event: event,
        description: opts[:description] || "Custom #{event} hook",
        add_to_config: opts[:add_to_config]
      ]

      {:ok, validated_opts}
    end
  end

  defp parse_matcher_input(nil), do: "*"
  defp parse_matcher_input("*"), do: "*"

  defp parse_matcher_input(matcher) when is_binary(matcher) do
    if String.contains?(matcher, ",") do
      matcher
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))
    else
      String.trim(matcher)
    end
  end

  defp get_full_module_name(module_name, event) do
    if String.contains?(to_string(module_name), ".") do
      Module.concat([module_name])
    else
      module_parts =
        if is_binary(module_name) do
          [module_name]
        else
          Module.split(module_name)
        end

      namespace_parts =
        case event do
          :post_tool_use -> ["Claude", "Hooks", "PostToolUse"]
          :pre_tool_use -> ["Claude", "Hooks", "PreToolUse"]
          :user_prompt_submit -> ["Claude", "Hooks", "UserPromptSubmit"]
          :notification -> ["Claude", "Hooks", "Notification"]
          :stop -> ["Claude", "Hooks", "Stop"]
          :subagent_stop -> ["Claude", "Hooks", "SubagentStop"]
          :pre_compact -> ["Claude", "Hooks", "PreCompact"]
        end

      Module.concat(namespace_parts ++ module_parts)
    end
  end

  defp generate_hook_module(igniter, module_name, opts) do
    full_module = get_full_module_name(module_name, opts[:event])
    file_path = Igniter.Project.Module.proper_location(igniter, full_module)
    content = generate_module_content(full_module, opts)
    Igniter.create_new_file(igniter, file_path, content)
  end

  defp generate_module_content(module, opts) do
    event = opts[:event]
    matcher = opts[:matcher]
    description = opts[:description]

    use_opts = [
      "event: #{inspect(event)}",
      "description: #{inspect(description)}"
    ]

    use_opts =
      if event in [:pre_tool_use, :post_tool_use] && matcher do
        use_opts ++ ["matcher: #{format_matcher_for_use(matcher)}"]
      else
        use_opts
      end

    handle_implementation = generate_handle_implementation(event)

    """
    defmodule #{inspect(module)} do
      @moduledoc \"\"\"
      #{description}
      
      This hook runs on the #{event} event#{if matcher && event in [:pre_tool_use, :post_tool_use], do: " for tools matching: #{format_matcher_for_display(matcher)}", else: ""}.
      
      For more information on Claude Code hooks, see:
      - https://docs.anthropic.com/en/docs/claude-code/hooks
      - https://docs.anthropic.com/en/docs/claude-code/hooks-guide
      \"\"\"
      
      use Claude.Hook,
        #{Enum.join(use_opts, ",\n    ")}
      
      alias Claude.Hooks.Helpers
      
      @impl Claude.Hook
      def handle(input) do
        #{handle_implementation}
      end
    end
    """
  end

  defp format_matcher_for_use("*"), do: ":*"

  defp format_matcher_for_use(matchers) when is_list(matchers) do
    formatted =
      matchers
      |> Enum.map(&":#{&1}")
      |> Enum.join(", ")

    "[#{formatted}]"
  end

  defp format_matcher_for_use(matcher) when is_binary(matcher) do
    ":#{matcher}"
  end

  defp format_matcher_for_display("*"), do: "*"
  defp format_matcher_for_display(matchers) when is_list(matchers), do: Enum.join(matchers, ", ")
  defp format_matcher_for_display(matcher) when is_binary(matcher), do: matcher

  defp generate_handle_implementation(:post_tool_use) do
    """
    case input.tool_input do
      %{file_path: path} when is_binary(path) ->
        IO.inspect(path, label: "File modified")
        :ok
        
      _ ->
        :ok
    end
    """
  end

  defp generate_handle_implementation(:pre_tool_use) do
    """
    case input.tool_name do
      "Bash" ->
        {:allow, nil}
        
      _ ->
        :ok
    end
    """
  end

  defp generate_handle_implementation(:user_prompt_submit) do
    """
    IO.inspect(input.prompt, label: "User prompt")
    :ok
    """
  end

  defp generate_handle_implementation(:notification) do
    """
    IO.inspect(input.message, label: "Notification")
    :ok
    """
  end

  defp generate_handle_implementation(:stop) do
    """
    :ok
    """
  end

  defp generate_handle_implementation(:subagent_stop) do
    """
    :ok
    """
  end

  defp generate_handle_implementation(:pre_compact) do
    """
    IO.inspect(input.trigger, label: "Compact trigger")
    :ok
    """
  end

  defp maybe_add_to_config(igniter, module_name, opts) do
    if opts[:add_to_config] do
      add_hook_to_claude_exs(igniter, module_name, opts)
    else
      igniter
    end
  end

  defp add_hook_to_claude_exs(igniter, module_name, opts) do
    claude_exs_path = ".claude.exs"
    full_module = get_full_module_name(module_name, opts[:event])

    if Igniter.exists?(igniter, claude_exs_path) do
      Igniter.update_file(igniter, claude_exs_path, fn source ->
        content = Rewrite.Source.get(source, :content)
        updated_content = add_module_to_hooks_list(content, full_module)
        Rewrite.Source.update(source, :content, updated_content)
      end)
    else
      igniter
      |> Igniter.add_warning(
        "No .claude.exs file found. Please add #{inspect(full_module)} to the hooks list manually."
      )
    end
  end

  defp add_module_to_hooks_list(content, module) do
    case Regex.run(~r/(hooks:\s*\[)(.*?)(\])/s, content) do
      [_full_match, _prefix, hooks_content, _suffix] ->
        module_string = inspect(module)

        if String.contains?(hooks_content, module_string) do
          content
        else
          trimmed_hooks = String.trim(hooks_content)

          new_hooks =
            if trimmed_hooks == "" do
              "\n    #{module_string}\n  "
            else
              "#{trimmed_hooks},\n    #{module_string}\n  "
            end

          String.replace(content, ~r/(hooks:\s*\[)(.*?)(\])/s, "\\g{1}#{new_hooks}\\g{3}")
        end

      nil ->
        content
    end
  end

  defp add_success_notice(igniter, module_name, opts) do
    full_module = get_full_module_name(module_name, opts[:event])
    file_path = Igniter.Project.Module.proper_location(igniter, full_module)

    notice = """
    Successfully generated hook module: #{inspect(full_module)}

    Location: #{file_path}
    Event: #{opts[:event]}
    #{if opts[:matcher] && opts[:event] in [:pre_tool_use, :post_tool_use], do: "Matcher: #{format_matcher_for_display(opts[:matcher])}\n", else: ""}Description: #{opts[:description]}

    #{if opts[:add_to_config], do: "✓ Added to .claude.exs hooks list", else: "! Remember to add #{inspect(full_module)} to your .claude.exs hooks list"}

    Next steps:
    1. Implement your hook logic in the generated module
    2. Run `mix claude.install` to activate the hook
    3. Test your hook by triggering the #{opts[:event]} event
    """

    Igniter.add_notice(igniter, notice)
  end

  defp prompt_for_module_name do
    IO.puts("Enter the hook module name (e.g., MyFormatter):")

    case IO.gets("> ") do
      :eof ->
        {:error, :cancelled}

      input ->
        case String.trim(input) do
          "" ->
            IO.puts("Error: Module name cannot be empty")
            {:error, :cancelled}

          name ->
            {:ok, name}
        end
    end
  end

  defp prompt_for_event do
    IO.puts("""

    Select hook event type:
    1. post_tool_use    - Runs after tool execution
    2. pre_tool_use     - Runs before tool execution (can block)
    3. user_prompt_submit - Runs when user submits a prompt
    4. notification     - Runs on Claude Code notifications
    5. stop            - Runs when Claude finishes responding
    6. subagent_stop   - Runs when a sub-agent finishes
    7. pre_compact     - Runs before context compaction
    """)

    case IO.gets("Enter number (1-7): ") do
      :eof ->
        {:error, :cancelled}

      input ->
        case String.trim(input) do
          "1" ->
            {:ok, :post_tool_use}

          "2" ->
            {:ok, :pre_tool_use}

          "3" ->
            {:ok, :user_prompt_submit}

          "4" ->
            {:ok, :notification}

          "5" ->
            {:ok, :stop}

          "6" ->
            {:ok, :subagent_stop}

          "7" ->
            {:ok, :pre_compact}

          _ ->
            IO.puts("Error: Invalid selection")
            {:error, :cancelled}
        end
    end
  end

  defp prompt_for_matcher(event) when event in [:pre_tool_use, :post_tool_use] do
    IO.puts("""

    Enter tool matcher pattern (comma-separated snake_case):
    Examples: write,edit,multi_edit or bash or * (all tools)
    Common tools: bash, edit, glob, grep, ls, multi_edit, notebook_edit, 
                  notebook_read, read, write, web_fetch, web_search
    """)

    case IO.gets("> ") |> String.trim() do
      "" -> {:ok, "*"}
      matcher -> {:ok, matcher}
    end
  end

  defp prompt_for_matcher(_event) do
    {:ok, nil}
  end

  defp prompt_for_description do
    IO.puts("\nEnter hook description:")

    case IO.gets("> ") |> String.trim() do
      "" -> {:ok, "Custom hook"}
      desc -> {:ok, desc}
    end
  end

  defp prompt_for_add_to_config do
    IO.puts("\nAdd hook to .claude.exs? (Y/n):")

    case IO.gets("> ") |> String.trim() |> String.downcase() do
      "" -> {:ok, true}
      "y" -> {:ok, true}
      "yes" -> {:ok, true}
      "n" -> {:ok, false}
      "no" -> {:ok, false}
      _ -> {:ok, true}
    end
  end

  defp prompt_for_description_with_default(nil) do
    prompt_for_description()
  end

  defp prompt_for_description_with_default(description) do
    IO.puts("\nDescription [#{description}]:")

    case IO.gets("> ") |> String.trim() do
      "" -> {:ok, description}
      new_desc -> {:ok, new_desc}
    end
  end

  defp prompt_for_add_to_config_with_default(nil) do
    prompt_for_add_to_config()
  end

  defp prompt_for_add_to_config_with_default(add_to_config) do
    default = if add_to_config, do: "Y", else: "n"
    IO.puts("\nAdd hook to .claude.exs? (#{default}):")

    case IO.gets("> ") |> String.trim() |> String.downcase() do
      "" -> {:ok, add_to_config}
      "y" -> {:ok, true}
      "yes" -> {:ok, true}
      "n" -> {:ok, false}
      "no" -> {:ok, false}
      _ -> {:ok, add_to_config}
    end
  end
end
