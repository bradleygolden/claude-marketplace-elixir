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
  require Logger

  def run([hook_identifier, event_type, json_params]) do
    case Hooks.find_hook_by_identifier(hook_identifier) do
      nil ->
        Logger.debug("Hook not found: #{hook_identifier}")
        :ok

      hook_module ->
        case ensure_module_loaded(hook_module) do
          :ok ->
            try do
              hook_module.run(event_type, json_params)
            rescue
              e ->
                Logger.error("Hook #{hook_identifier} failed: #{Exception.message(e)}")
                :ok
            end

          {:error, reason} ->
            Logger.error("Failed to load hook module #{hook_module}: #{reason}")
            :ok
        end
    end
  end

  def run(_args) do
    :ok
  end

  defp ensure_module_loaded(module) do
    if Code.ensure_loaded?(module) do
      :ok
    else
      # Try regular compilation first without forcing
      case System.cmd("mix", ["compile"], stderr_to_stdout: true) do
        {_, 0} ->
          if Code.ensure_loaded?(module) do
            :ok
          else
            # Only force compilation if the module still isn't loaded
            force_compile_and_check(module)
          end

        {output, _} ->
          {:error, "Compilation failed: #{output}"}
      end
    end
  end
  
  defp force_compile_and_check(module) do
    Logger.debug("Module #{module} not found, forcing compilation")
    
    case System.cmd("mix", ["compile", "--force"], stderr_to_stdout: true) do
      {_, 0} ->
        if Code.ensure_loaded?(module) do
          :ok
        else
          {:error, "Module not found after forced compilation"}
        end

      {output, _} ->
        {:error, "Forced compilation failed: #{output}"}
    end
  end
end
