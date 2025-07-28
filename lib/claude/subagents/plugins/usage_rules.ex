defmodule Claude.Subagents.Plugins.UsageRules do
  @moduledoc """
  Plugin that enhances subagents with usage rules from specified dependencies.

  This plugin reads usage-rules.md files from dependencies and includes
  them in the subagent's prompt to provide context-specific guidance.

  ## Dependency Specifications

  Dependencies can be specified as:
  - `:package_name` - Include the main usage-rules.md file
  - `"package_name:sub_rule"` - Include a specific sub-rule from usage-rules/sub_rule.md
  - `"package_name:all"` - Include all sub-rules from the usage-rules/ folder
  """

  @behaviour Claude.Subagents.Plugin

  alias Claude.Core.Project

  @impl true
  def name, do: :usage_rules

  @impl true
  def description do
    "Enhances subagent with usage rules from specified dependencies"
  end

  @impl true
  def validate_config(opts) do
    case opts do
      %{deps: deps} when is_list(deps) ->
        if Enum.all?(deps, &valid_dep_spec?/1) do
          :ok
        else
          {:error, "Deps must be atoms or strings with optional :sub_rule syntax"}
        end

      _ ->
        {:error, "UsageRules plugin requires 'deps' list in config"}
    end
  end

  defp valid_dep_spec?(spec) when is_atom(spec), do: true
  defp valid_dep_spec?(spec) when is_binary(spec), do: true
  defp valid_dep_spec?(_), do: false

  @impl true
  def enhance(%{deps: deps}) do
    expanded_deps = expand_dep_specs(deps)

    prompt_additions =
      expanded_deps
      |> Enum.map(&fetch_usage_rules/1)
      |> Enum.reject(&is_nil/1)
      |> format_usage_rules()

    enhancement = %{
      prompt_additions: prompt_additions,
      tools: [],
      metadata: %{
        source: :usage_rules,
        deps: deps,
        found_count: count_found_rules(prompt_additions)
      }
    }

    {:ok, enhancement}
  end

  defp expand_dep_specs(deps) do
    Enum.flat_map(deps, fn dep_spec ->
      case parse_dep_spec(dep_spec) do
        {package, nil} ->
          # Just the main package
          [{package, nil}]

        {package, "all"} ->
          # Expand to all sub-rules
          sub_rules = find_sub_rules(package)

          if Enum.empty?(sub_rules) do
            # Fallback to main if no sub-rules
            [{package, nil}]
          else
            Enum.map(sub_rules, fn sub_rule -> {package, sub_rule} end)
          end

        {package, sub_rule} ->
          # Specific sub-rule
          [{package, sub_rule}]
      end
    end)
  end

  defp parse_dep_spec(spec) when is_atom(spec), do: {spec, nil}

  defp parse_dep_spec(spec) when is_binary(spec) do
    case String.split(spec, ":", parts: 2) do
      [package] -> {String.to_atom(package), nil}
      [package, sub_rule] -> {String.to_atom(package), sub_rule}
    end
  end

  defp find_sub_rules(package) do
    usage_rules_dir = Path.join([Project.root(), "deps", to_string(package), "usage-rules"])

    case File.ls(usage_rules_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&Path.rootname/1)
        |> Enum.sort()

      {:error, _} ->
        []
    end
  end

  defp fetch_usage_rules({package, nil}) do
    # Fetch main usage rules
    usage_rules_paths = [
      Path.join([Project.root(), "deps", to_string(package), "usage-rules.md"]),
      Path.join([Project.root(), "deps", to_string(package), "usage_rules.md"]),
      Path.join([Project.root(), "deps", to_string(package), "USAGE_RULES.md"])
    ]

    Enum.find_value(usage_rules_paths, fn path ->
      case File.read(path) do
        {:ok, content} -> {package, nil, content}
        _ -> nil
      end
    end)
  end

  defp fetch_usage_rules({package, sub_rule}) do
    # Fetch specific sub-rule
    sub_rule_path = Path.join([Project.root(), "deps", to_string(package), "usage-rules", "#{sub_rule}.md"])

    case File.read(sub_rule_path) do
      {:ok, content} -> {package, sub_rule, content}
      _ -> nil
    end
  end

  defp format_usage_rules([]), do: nil

  defp format_usage_rules(rules) do
    sections =
      Enum.map(rules, fn
        {dep, nil, content} ->
          """
          ## #{format_dep_name(dep)} Usage Rules

          #{content}
          """

        {dep, sub_rule, content} ->
          """
          ## #{format_dep_name(dep)}: #{format_sub_rule_name(sub_rule)}

          #{content}
          """
      end)

    """
    # Dependency Usage Rules

    The following usage rules are available for dependencies in this project:

    #{Enum.join(sections, "\n")}
    """
  end

  defp format_sub_rule_name(sub_rule) do
    sub_rule
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp format_dep_name(dep) do
    dep
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp count_found_rules(nil), do: 0

  defp count_found_rules(prompt_additions) do
    # Count actual dependency sections, not the header
    # Matches both "## Package Usage Rules" and "## Package: Sub Rule"
    prompt_additions
    |> String.split("\n")
    |> Enum.count(&String.match?(&1, ~r/^## .+( Usage Rules|:.+)$/))
  end
end
