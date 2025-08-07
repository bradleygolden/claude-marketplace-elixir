defmodule Claude.Hooks.Defaults do
  @moduledoc """
  Defines default hook configurations for common tasks.

  Atoms in hook configurations are expanded to their full definitions
  based on the event type they're used in.
  """

  @doc """
  Expands an atom hook to its full configuration based on the event type.

  Returns the expanded hook configuration or the original if not an atom.
  """
  def expand_hook(hook, event_type) when is_atom(hook) do
    case {hook, event_type} do
      {:compile, :stop} ->
        {"compile --warnings-as-errors", stop_on_failure?: true}

      {:compile, :subagent_stop} ->
        {"compile --warnings-as-errors", stop_on_failure?: true}

      {:compile, :post_tool_use} ->
        {"compile --warnings-as-errors",
         when: [:write, :edit, :multi_edit], stop_on_failure?: true}

      {:compile, :pre_tool_use} ->
        {"compile --warnings-as-errors",
         when: "Bash", command: ~r/^git commit/, stop_on_failure?: true}

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
end
