defmodule Claude.CLI.Hooks.Run do
  @moduledoc """
  Handles dynamic hook execution.
  This is called by Claude Code hooks, not directly by users.

  Usage:
    mix claude hooks run <hook_identifier>

  The hook receives the full Claude Code JSON via stdin.

  Example:
    echo '{"session_id": "123", "event": {...}}' | mix claude hooks run post_tool_use.elixir_formatter
  """

  alias Claude.Hooks

  def run([hook_identifier]) do
    input = IO.read(:stdio, :eof)

    case Hooks.find_hook_by_identifier(hook_identifier) do
      nil ->
        :ok

      hook_module ->
        hook_module.run(input)
    end
  end

  def run(_args) do
    :ok
  end
end
