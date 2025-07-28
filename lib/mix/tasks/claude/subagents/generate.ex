defmodule Mix.Tasks.Claude.Subagents.Generate do
  @moduledoc """
  Generates Claude Code subagent markdown files from .claude.exs configuration.

  ## Usage

      mix claude.subagents.generate

  This task will:
  1. Read subagent configurations from .claude.exs
  2. Apply any configured plugins (e.g., usage_rules)
  3. Generate markdown files in .claude/agents/
  4. Report on generated files

  ## Configuration

  Subagents are configured in .claude.exs:

      %{
        subagents: [
          %{
            name: "Ecto Expert",
            description: "Expert in Ecto database operations",
            prompt: "You are an expert in Ecto...",
            tools: [:read, :grep, :task],
            usage_rules: ["ecto", "ecto_sql"]
          }
        ]
      }
  """

  use Mix.Task

  alias Claude.Core.{ClaudeExs, Project}
  alias Claude.Subagents
  alias Claude.Subagents.Subagent
  alias Claude.Tools
  alias Claude.Utils.Shell

  @agents_dir "agents"
  @shortdoc "Generate subagent markdown files from .claude.exs"

  @impl Mix.Task
  def run(_args) do
    Shell.info("Generating Claude subagents...")

    with {:ok, config} <- ClaudeExs.load(),
         subagent_configs <- ClaudeExs.get_subagents(config),
         :ok <- ensure_agents_directory(),
         {:ok, results} <- generate_subagents(subagent_configs) do
      display_results(results)
    else
      {:error, :not_found} ->
        Shell.error("No .claude.exs file found")
        {:error, "No .claude.exs file found"}

      {:error, reason} ->
        Shell.error("Failed to generate subagents: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp ensure_agents_directory do
    agents_path = Path.join(Project.claude_path(), @agents_dir)
    File.mkdir_p(agents_path)
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

  defp display_results(results) do
    Shell.blank()
    Shell.success("Generated #{length(results)} subagent(s):")

    Enum.each(results, fn {name, path} ->
      relative_path = Path.relative_to(path, Project.root())
      Shell.bullet("#{name} → #{relative_path}")
    end)

    Shell.blank()
    Shell.info("Subagents are now available in Claude Code.")
  end
end
