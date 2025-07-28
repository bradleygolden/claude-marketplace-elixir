defmodule ExampleHooks.SecurityScanner do
  @moduledoc """
  Example custom hook that scans for security patterns.
  Used for testing custom hook registration with PreToolUse events.
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :pre_tool_use,
    matcher: [:bash],
    description: "Scans commands for potential security issues"
  
  @impl Claude.Hooks.Hook.Behaviour
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "cd $CLAUDE_PROJECT_DIR && mix claude hooks run example_hooks.security_scanner"
    }
  end

  @impl true
  def run(:eof), do: :ok
  
  def run(json_input) when is_binary(json_input) do
    with {:ok, data} <- Jason.decode(json_input),
         command <- get_in(data, ["tool_input", "command"]) || "" do
      dangerous_patterns = [
        ~r/rm\s+-rf\s+\//,
        ~r/curl.*\|\s*sh/,
        ~r/eval\(/
      ]
      
      if Enum.any?(dangerous_patterns, &Regex.match?(&1, command)) do
        {:error, "Command contains potentially dangerous patterns"}
      else
        :ok
      end
    else
      _ -> :ok
    end
  end
end