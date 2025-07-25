defmodule Claude.CLI.Hooks.Run do
  @moduledoc """
  Handles dynamic hook execution.
  This is called by Claude Code hooks, not directly by users.

  Usage:
    mix claude hooks run <hook_identifier> <event_type> <json_params>

  Example:
    mix claude hooks run post_tool_use.elixir_formatter "Write" '{"file_path": "lib/foo.ex"}'
  """

  alias Claude.Hooks

  def run([hook_identifier, event_type, json_params]) do
    case Hooks.find_hook_by_identifier(hook_identifier) do
      nil ->
        # Unknown hook, exit silently
        :ok

      hook_module ->
        hook_module.run(event_type, json_params)
    end
  end

  def run(_args) do
    # Invalid arguments, just exit silently
    :ok
  end
end
