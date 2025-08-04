defmodule Claude.Hooks.PreToolUse.PreCommitCheck do
  @moduledoc """
  Pre-commit hook that validates formatting, compilation, and dependencies before allowing commits.

  This hook runs before commit operations and blocks the commit if:
  - Any Elixir files are not properly formatted
  - The project has compilation errors or warnings
  - There are unused dependencies in mix.lock
  """

  use Claude.Hook,
    event: :pre_tool_use,
    matcher: :bash,
    description: "Validates formatting, compilation, and dependencies before allowing commits"

  alias Claude.Hooks.{Helpers, ToolInputs}

  @impl true
  def handle(%Claude.Hooks.Events.PreToolUse.Input{} = input) do
    case input.tool_input do
      %ToolInputs.Bash{command: command} when is_binary(command) ->
        if String.contains?(command, "git commit") do
          validate_commit()
        else
          :ok
        end

      _ ->
        :ok
    end
  end

  defp validate_commit do
    with :ok <- check_formatting(),
         :ok <- check_compilation(),
         :ok <- check_unused_dependencies() do
      {:allow, "Pre-commit checks passed"}
    else
      {:error, reason} ->
        {:deny, format_error_message(reason)}
    end
  end

  defp check_formatting do
    case Helpers.system_cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:error, {:formatting_failed, output}}
    end
  end

  defp check_compilation do
    case Helpers.system_cmd("mix", ["compile", "--warnings-as-errors"], stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:error, {:compilation_failed, output}}
    end
  end

  defp check_unused_dependencies do
    case Helpers.system_cmd("mix", ["deps.unlock", "--check-unused"], stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:error, {:unused_dependencies, output}}
    end
  end

  defp format_error_message({:formatting_failed, output}) do
    """
    Pre-commit check failed: Formatting issues detected!

    #{output}

    Please run 'mix format' to fix formatting issues before committing.
    """
  end

  defp format_error_message({:compilation_failed, output}) do
    """
    Pre-commit check failed: Compilation errors detected!

    #{output}

    Please fix compilation errors and warnings before committing.
    """
  end

  defp format_error_message({:unused_dependencies, output}) do
    """
    Pre-commit check failed: Unused dependencies detected!

    #{output}

    Please run 'mix deps.unlock --unused' to remove unused dependencies.
    """
  end

  defp format_error_message(reason) do
    "Pre-commit check failed: #{inspect(reason)}"
  end
end
