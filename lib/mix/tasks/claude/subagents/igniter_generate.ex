defmodule Mix.Tasks.Claude.Subagents.IgniterGenerate do
  @moduledoc false
  # Internal task for Igniter composition with mix claude.install

  use Igniter.Mix.Task

  alias Claude.Core.{ClaudeExs, Project}
  alias Claude.Subagents
  alias Claude.Subagents.Subagent
  alias Claude.Tools

  @agents_dir "agents"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :claude,
      example: "mix claude.subagents.generate",
      only: [:dev]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    case ClaudeExs.load() do
      {:ok, config} ->
        subagent_configs = ClaudeExs.get_subagents(config)
        process_subagents(igniter, subagent_configs)

      {:error, :not_found} ->
        igniter
        |> Igniter.add_warning("No .claude.exs file found. Skipping subagent generation.")

      {:error, reason} ->
        igniter
        |> Igniter.add_warning("Failed to load .claude.exs: #{inspect(reason)}")
    end
  end

  @impl Igniter.Mix.Task
  def supports_umbrella?, do: false

  defp process_subagents(igniter, []) do
    igniter
  end

  defp process_subagents(igniter, configs) do
    ensure_agents_directory()
    results = generate_subagents(configs)

    case results do
      {:ok, generated} ->
        igniter
        |> add_generated_files(generated)
        |> Igniter.add_notice(format_success_message(generated))

      {:error, errors} ->
        igniter
        |> Igniter.add_warning(format_error_message(errors))
    end
  end

  defp add_generated_files(igniter, results) do
    Enum.reduce(results, igniter, fn {_name, path}, acc ->
      relative_path = Path.relative_to_cwd(path)
      content = File.read!(path)

      Igniter.create_or_update_file(acc, relative_path, content, fn source ->
        Rewrite.Source.update(source, :content, content)
      end)
    end)
  end

  defp generate_subagents(configs) do
    results =
      Enum.map(configs, fn config ->
        with {:ok, subagent} <- ClaudeExs.subagent_from_config(config),
             {:ok, enhanced_subagent} <- Subagents.apply_plugins(subagent),
             {:ok, path} <- write_subagent_markdown(enhanced_subagent) do
          {:ok, {enhanced_subagent.name, path}}
        else
          {:error, reason} ->
            {:error, {config[:name] || "Unknown", reason}}
        end
      end)

    errors = Enum.filter(results, &match?({:error, _}, &1))

    if errors == [] do
      {:ok, Enum.map(results, fn {:ok, result} -> result end)}
    else
      {:error, errors}
    end
  end

  defp write_subagent_markdown(subagent) do
    filename = subagent_filename(subagent.name)
    path = Path.join([Project.claude_path(), @agents_dir, filename])
    content = generate_markdown(subagent)

    case File.write(path, content) do
      :ok -> {:ok, path}
      error -> error
    end
  end

  defp subagent_filename(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
    |> Kernel.<>(".md")
  end

  defp generate_markdown(%Subagent{} = subagent) do
    tools_section = generate_tools_section(subagent.tools)
    usage_rules_section = extract_usage_rules_section(subagent.prompt)

    """
    # #{subagent.name}

    #{subagent.description}

    ## Prompt

    #{subagent.prompt}

    ## Configuration

    #{tools_section}

    #{usage_rules_section}
    """
    |> String.trim()
  end

  defp generate_tools_section([]), do: "### Tools\n\nThis subagent has access to all tools."

  defp generate_tools_section(tools) do
    tools_list =
      tools
      |> Enum.map(&Tools.tool_to_string/1)
      |> Enum.map(&"- #{&1}")
      |> Enum.join("\n")

    """
    ### Tools

    This subagent has access to the following tools:

    #{tools_list}
    """
    |> String.trim()
  end

  defp extract_usage_rules_section(prompt) do
    # Check if the prompt already contains usage rules section
    if String.contains?(prompt, "## Usage Rules") || String.contains?(prompt, "# Usage Rules") do
      ""
    else
      ""
    end
  end

  defp ensure_agents_directory do
    agents_path = Path.join(Project.claude_path(), @agents_dir)
    File.mkdir_p(agents_path)
  end

  defp format_success_message(results) do
    lines = [
      "Generated #{length(results)} subagent(s):",
      ""
    ]

    result_lines =
      Enum.map(results, fn {name, path} ->
        relative_path = Path.relative_to(path, Project.root())
        "• #{name} → #{relative_path}"
      end)

    (lines ++ result_lines ++ ["", "Subagents are now available in Claude Code."])
    |> Enum.join("\n")
  end

  defp format_error_message(errors) do
    error_lines =
      Enum.map(errors, fn {:error, {name, reason}} ->
        "• #{name}: #{inspect(reason)}"
      end)

    (["Failed to generate some subagents:"] ++ error_lines)
    |> Enum.join("\n")
  end
end
