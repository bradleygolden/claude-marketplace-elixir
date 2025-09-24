defmodule Mix.Tasks.Claude.Gen.Subagent do
  @shortdoc "Generate a new Claude subagent"

  @moduledoc """
  Generate a new Claude subagent for specialized AI assistance.

  This task helps you create a new subagent that can be delegated to by Claude Code
  for specific tasks. Subagents are specialized AI assistants with their own system
  prompts and tool permissions.

  ## Usage

  ### Interactive Mode

      mix claude.gen.subagent

  The task will interactively prompt you for:

  ### Non-Interactive Mode (for AI agents)

      mix claude.gen.subagent --name my-assistant --description "Database query helper" \\
        --tools "read,grep,bash" --prompt "You are a database expert."

  ## Options

    * `--name` - The subagent name (lowercase-hyphen-separated)
    * `--description` - When Claude should invoke this subagent
    * `--tools` - Comma-separated list of tools (optional, defaults to read,grep,glob)
    * `--prompt` - The system prompt defining behavior

  When all required flags are provided (name, description, prompt), the task runs
  in non-interactive mode, making it suitable for automation and AI agent invocation.

  In interactive mode, the task prompts for:

  1. **Name** - A descriptive name for your subagent (e.g., "database-migration-agent")
  2. **Description** - When this subagent should be invoked (critical for delegation)
  3. **Tools** - Which tools the subagent needs (optional, defaults to minimal set)
  4. **Prompt** - The system prompt that defines the subagent's behavior

  ## Delegation Descriptions

  The description is critical for automatic delegation. Use clear, action-oriented language:

  Good examples:
  - "MUST BE USED for all database migration tasks"
  - "Use PROACTIVELY when user asks about API documentation"
  - "Expert in refactoring Elixir code to follow best practices"

  Poor examples:
  - "Database helper" (too vague)
  - "Helps with migrations" (not directive enough)

  ## Tool Selection

  Choose minimal tools for better performance:
  - Code analysis: `read, grep, glob`
  - Code modification: `read, edit, multi_edit`
  - Test execution: `read, edit, bash`
  - Documentation: `read, write, web_search`

  Never include `task` (prevents delegation loops).

  ## Example

      $ mix claude.gen.subagent
      
      Enter subagent name: Test Runner Agent
      Enter description (when to invoke): MUST BE USED for running and analyzing test results
      Enter tools (comma-separated, optional): read, grep, bash
      Enter system prompt (multi-line, end with empty line):
      # Purpose
      You are an expert test runner and analyzer for Elixir projects.
      
      ## Instructions
      When invoked:
      1. First check for test files using grep
      2. Run tests with appropriate mix commands
      3. Analyze failures and suggest fixes
      
      (empty line to finish)

  The generated subagent will be:
  1. Added to your `.claude.exs` configuration
  2. Written to `.claude/agents/test-runner-agent.md`
  3. Available immediately after running `mix claude.install`
  """

  use Igniter.Mix.Task

  @tool_mappings %{
    "bash" => :bash,
    "edit" => :edit,
    "glob" => :glob,
    "grep" => :grep,
    "ls" => :ls,
    "multi_edit" => :multi_edit,
    "multiedit" => :multi_edit,
    "notebook_edit" => :notebook_edit,
    "notebook_read" => :notebook_read,
    "read" => :read,
    "task" => :task,
    "todo_write" => :todo_write,
    "web_fetch" => :web_fetch,
    "web_search" => :web_search,
    "write" => :write
  }

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example:
        "mix claude.gen.subagent --name my-assistant --description \"Helps with database queries\" --tools read,grep --prompt \"You are a database expert.\"",
      only: [:dev],
      schema: [
        name: :string,
        description: :string,
        tools: :string,
        prompt: :string
      ]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    opts = igniter.args.options

    if has_required_flags?(opts) do
      generate_from_flags(igniter, opts)
    else
      IO.puts("\n🤖 Claude Subagent Generator\n")

      with {:ok, name} <- prompt_for_name(),
           {:ok, description} <- prompt_for_description(),
           {:ok, tools} <- prompt_for_tools(),
           {:ok, prompt} <- prompt_for_prompt() do
        subagent_config = %{
          name: name,
          description: description,
          tools: tools,
          prompt: prompt
        }

        igniter
        |> add_subagent_to_claude_exs(subagent_config)
        |> generate_subagent_file(subagent_config)
        |> add_success_notice(subagent_config)
      else
        {:error, :cancelled} ->
          igniter
          |> Igniter.add_notice("Subagent generation cancelled.")

        {:error, message} ->
          igniter
          |> Igniter.add_issue(message)
      end
    end
  end

  defp has_required_flags?(opts) do
    opts[:name] && opts[:description] && opts[:prompt]
  end

  defp generate_from_flags(igniter, opts) do
    tools = parse_tools_from_string(opts[:tools] || "")

    subagent_config = %{
      name: opts[:name],
      description: opts[:description],
      tools: tools,
      prompt: opts[:prompt]
    }

    igniter
    |> add_subagent_to_claude_exs(subagent_config)
    |> generate_subagent_file(subagent_config)
    |> add_success_notice(subagent_config)
  end

  defp parse_tools_from_string(""), do: [:read, :grep, :glob]

  defp parse_tools_from_string(tools_string) do
    parse_tools(tools_string)
  end

  defp prompt_for_name do
    IO.puts("Enter the name for your subagent (lowercase-hyphen-separated):")

    case IO.gets("> ") |> String.trim() do
      "" ->
        {:error, "Name cannot be empty"}

      name ->
        {:ok, name}
    end
  end

  defp prompt_for_description do
    IO.puts("""

    Enter description (when to invoke this subagent):
    💡 Tip: Use directive language like "MUST BE USED for...", "Use PROACTIVELY when..."
    """)

    case IO.gets("Description: ") |> String.trim() do
      "" ->
        {:error, "Description cannot be empty"}

      description ->
        {:ok, description}
    end
  end

  defp prompt_for_tools do
    IO.puts("""

    Enter tools (comma-separated snake_case, press Enter for default minimal set):
    Available: bash, edit, glob, grep, ls, multi_edit, notebook_edit, notebook_read, 
               read, todo_write, web_fetch, web_search, write
    ⚠️  Warning: Avoid 'task' to prevent delegation loops
    """)

    case IO.gets("Tools: ") |> String.trim() do
      "" ->
        {:ok, [:read, :grep, :glob]}

      tools_input ->
        parsed_tools = parse_tools(tools_input)

        if :task in parsed_tools do
          IO.puts("\n⚠️  Warning: Including 'task' tool can cause delegation loops!")
          IO.puts("Are you sure you want to include it? (y/N)")

          case IO.gets("") |> String.trim() |> String.downcase() do
            "y" -> {:ok, parsed_tools}
            _ -> prompt_for_tools()
          end
        else
          {:ok, parsed_tools}
        end
    end
  end

  defp parse_tools(tools_input) do
    tools_input
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&Map.get(@tool_mappings, &1))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp prompt_for_prompt do
    IO.puts("""

    Enter system prompt (multi-line input, end with an empty line):
    💡 Tip: Include sections for Purpose, Instructions, Context Discovery, and Best Practices
    """)

    IO.puts("\nPrompt:")
    lines = read_multiline_input()

    if lines == [] do
      {:error, "Prompt cannot be empty"}
    else
      {:ok, Enum.join(lines, "\n")}
    end
  end

  defp read_multiline_input(lines \\ []) do
    case IO.gets("") do
      :eof ->
        Enum.reverse(lines)

      input ->
        line = String.trim_trailing(input, "\n")

        if line == "" && lines != [] do
          Enum.reverse(lines)
        else
          read_multiline_input([line | lines])
        end
    end
  end

  defp add_subagent_to_claude_exs(igniter, config) do
    claude_exs_path = ".claude.exs"

    if Igniter.exists?(igniter, claude_exs_path) do
      Igniter.update_file(igniter, claude_exs_path, fn source ->
        content = Rewrite.Source.get(source, :content)
        updated_content = add_subagent_to_content(content, config)
        Rewrite.Source.update(source, :content, updated_content)
      end)
    else
      content = generate_claude_exs_with_subagent(config)
      Igniter.create_new_file(igniter, claude_exs_path, content)
    end
  end

  defp add_subagent_to_content(content, config) do
    with {existing_config, _} <- Code.eval_string(content),
         %{} <- existing_config do
      existing_subagents = Map.get(existing_config, :subagents, [])

      filtered_subagents =
        Enum.reject(existing_subagents, fn subagent ->
          Map.get(subagent, :name) == config.name
        end)

      new_subagent = %{
        name: config.name,
        description: config.description,
        prompt: config.prompt,
        tools: config.tools
      }

      updated_subagents = filtered_subagents ++ [new_subagent]
      updated_config = Map.put(existing_config, :subagents, updated_subagents)

      format_claude_exs_map(updated_config)
    else
      _ ->
        subagent_code = format_subagent_config(config, "    ")

        if content =~ ~r/subagents:\s*\[/ do
          content
          |> String.replace(~r/(subagents:\s*\[.*?)([\s\n]*\])/s, fn _full, prefix, suffix ->
            if prefix =~ ~r/\S/ do
              "#{prefix},\n#{subagent_code}#{suffix}"
            else
              "#{prefix}\n#{subagent_code}#{suffix}"
            end
          end)
        else
          String.replace(
            content,
            ~r/(%\{.*?)(\s*\})/s,
            "\\1,\n  subagents: [\n#{subagent_code}\n  ]\\2"
          )
        end
    end
  end

  defp format_claude_exs_map(config) do
    entries =
      Enum.map(config, fn
        {:subagents, subagents} when is_list(subagents) ->
          subagents_str =
            subagents
            |> Enum.map(&format_subagent_config(&1, "    "))
            |> Enum.join(",\n")

          "  subagents: [\n#{subagents_str}\n  ]"

        {key, value} ->
          "  #{key}: #{inspect(value, limit: :infinity)}"
      end)
      |> Enum.join(",\n")

    "%{\n#{entries}\n}"
  end

  defp format_subagent_config(config, indent) do
    # Handle both atom and string keys
    name = Map.get(config, :name) || Map.get(config, "name")
    description = Map.get(config, :description) || Map.get(config, "description")
    prompt = Map.get(config, :prompt) || Map.get(config, "prompt")
    tools = Map.get(config, :tools) || Map.get(config, "tools") || []

    tools_str = inspect(tools, limit: :infinity)
    escaped_prompt = String.replace(prompt || "", ~s("""), ~s(\\"""))

    parts = [
      indent <> "%{\n",
      indent <> "  name: " <> inspect(name),
      ",\n" <> indent <> "  description: " <> inspect(description)
    ]

    parts =
      if prompt do
        parts ++
          [
            ",\n" <>
              indent <>
              "  prompt: \"\"\"\n" <>
              indent_lines(escaped_prompt, indent <> "  ") <>
              "\n" <> indent <> "  \"\"\""
          ]
      else
        parts
      end

    parts =
      if tools != [] do
        parts ++ [",\n" <> indent <> "  tools: " <> tools_str]
      else
        parts
      end

    Enum.join(parts ++ ["\n" <> indent <> "}"], "")
  end

  defp indent_lines(text, indent) do
    text
    |> String.split("\n")
    |> Enum.map(fn line ->
      if line == "" do
        ""
      else
        indent <> line
      end
    end)
    |> Enum.join("\n")
  end

  defp generate_claude_exs_with_subagent(config) do
    "%{\n" <>
      "  hooks: %{\n" <>
      "    post_tool_use: [\n" <>
      "      %{\n" <>
      "        id: :elixir_quality_checks,\n" <>
      "        matcher: [:write, :edit, :multi_edit],\n" <>
      "        tasks: [\n" <>
      "          \"format {{tool_input.file_path}}\",\n" <>
      "          \"compile --warnings-as-errors\"\n" <>
      "        ]\n" <>
      "      }\n" <>
      "    ]\n" <>
      "  },\n" <>
      "  subagents: [\n" <>
      format_subagent_config(config, "    ") <>
      "\n" <>
      "  ]\n" <>
      "}"
  end

  defp generate_subagent_file(igniter, config) do
    filename = subagent_filename(config.name)
    file_path = Path.join([".claude", "agents", filename])

    content = generate_subagent_markdown(config)

    Igniter.create_or_update_file(igniter, file_path, content, fn source ->
      Rewrite.Source.update(source, :content, content)
    end)
  end

  defp subagent_filename(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> Kernel.<>(".md")
  end

  defp generate_subagent_markdown(config) do
    name =
      config.name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    tools_line =
      if config.tools != [] do
        tools_str =
          config.tools
          |> Enum.map(&tool_to_string/1)
          |> Enum.join(", ")

        "\ntools: #{tools_str}"
      else
        ""
      end

    """
    ---
    name: #{name}
    description: #{config.description}#{tools_line}
    ---

    #{config.prompt}

    ## Reference

    For more information on Claude Code subagents, see:
    - https://docs.anthropic.com/en/docs/claude-code/sub-agents
    """
  end

  defp tool_to_string(:bash), do: "Bash"
  defp tool_to_string(:edit), do: "Edit"
  defp tool_to_string(:glob), do: "Glob"
  defp tool_to_string(:grep), do: "Grep"
  defp tool_to_string(:ls), do: "LS"
  defp tool_to_string(:multi_edit), do: "MultiEdit"
  defp tool_to_string(:notebook_edit), do: "NotebookEdit"
  defp tool_to_string(:notebook_read), do: "NotebookRead"
  defp tool_to_string(:read), do: "Read"
  defp tool_to_string(:task), do: "Task"
  defp tool_to_string(:todo_write), do: "TodoWrite"
  defp tool_to_string(:web_fetch), do: "WebFetch"
  defp tool_to_string(:web_search), do: "WebSearch"
  defp tool_to_string(:write), do: "Write"
  defp tool_to_string(tool), do: Atom.to_string(tool)

  defp add_success_notice(igniter, config) do
    filename = subagent_filename(config.name)
    file_path = Path.join([".claude", "agents", filename])

    notice = """
    ✅ Successfully generated subagent: #{config.name}

    Configuration added to: .claude.exs
    Subagent file created: #{file_path}

    Tools: #{Enum.map_join(config.tools, ", ", &tool_to_string/1)}

    Next steps:
    1. Review the generated subagent in #{file_path}
    2. Run `mix claude.install` to activate the subagent
    3. Test delegation by asking Claude to perform tasks matching: "#{config.description}"

    💡 Tips:
    - Subagents start fresh each invocation (no memory between calls)
    - Keep prompts focused on specific tasks
    - Use minimal tools for better performance
    """

    Igniter.add_notice(igniter, notice)
  end
end
