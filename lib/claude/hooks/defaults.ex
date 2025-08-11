defmodule Claude.Hooks.Defaults do
  @moduledoc """
  Defines default hook configurations for common tasks.

  Atoms in hook configurations are expanded to their full definitions
  based on the event type they're used in.
  """

  @doc """
  Expands an atom hook to its full configuration based on the event type.

  Returns the expanded hook configuration or the original if not an atom.
  Supports both plain atoms and tuples with atoms as the first element.
  """
  def expand_hook({atom, opts}, event_type) when is_atom(atom) and is_list(opts) do
    expanded = expand_hook(atom, event_type)

    if expanded == atom do
      {atom, opts}
    else
      merge_hook_with_opts(expanded, opts)
    end
  end

  def expand_hook(hook, event_type) when is_atom(hook) do
    case {hook, event_type} do
      {:compile, :stop} ->
        {"compile --warnings-as-errors", halt_pipeline?: true}

      {:compile, :subagent_stop} ->
        {"compile --warnings-as-errors", halt_pipeline?: true}

      {:compile, :post_tool_use} ->
        {"compile --warnings-as-errors", when: [:write, :edit, :multi_edit], halt_pipeline?: true}

      {:compile, :pre_tool_use} ->
        {"compile --warnings-as-errors",
         when: "Bash", command: ~r/^git commit/, halt_pipeline?: true}

      {:format, :stop} ->
        "format --check-formatted"

      {:format, :subagent_stop} ->
        "format --check-formatted"

      {:format, :post_tool_use} ->
        {"format --check-formatted {{tool_input.file_path}}", when: [:write, :edit, :multi_edit]}

      {:format, :pre_tool_use} ->
        {"format --check-formatted", when: "Bash", command: ~r/^git commit/}

      {:unused_deps, :pre_tool_use} ->
        {"deps.unlock --check-unused", when: "Bash", command: ~r/^git commit/}

      _ ->
        hook
    end
  end

  def expand_hook(hook, _event_type), do: hook

  @doc """
  Expands all hooks in a list for a given event type.
  """
  def expand_hooks(hooks, event_type) when is_list(hooks) do
    Enum.map(hooks, &expand_hook(&1, event_type))
  end

  def expand_hooks(hooks, _event_type), do: hooks

  defp merge_hook_with_opts(expanded, opts) do
    case expanded do
      {command, existing_opts} when is_binary(command) and is_list(existing_opts) ->
        {command, Keyword.merge(existing_opts, opts)}

      command when is_binary(command) ->
        {command, opts}

      _ ->
        expanded
    end
  end
end
