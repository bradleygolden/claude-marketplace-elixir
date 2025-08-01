defmodule Claude.Hooks.PreToolUse.PreCommitCheck do
  @moduledoc """
  Pre-commit hook that validates formatting, compilation, and dependencies before allowing commits.

  This hook runs before commit operations and blocks the commit if:
  - Any Elixir files are not properly formatted
  - The project has compilation errors or warnings
  - There are unused dependencies in mix.lock
  """

  use Claude.Hooks.Hook.Behaviour,
    event: :pre_tool_use,
    matcher: :bash,
    description: "Validates formatting, compilation, and dependencies before allowing commits"

  alias Claude.Hooks.{Helpers, JsonOutput}

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof) do
    :ok
  end

  def run(json_input) when is_binary(json_input) do
    case Claude.Hooks.Events.PreToolUse.Input.from_json(json_input) do
      {:ok, %Claude.Hooks.Events.PreToolUse.Input{} = input} ->
        handle_hook_input(input)

      {:error, _} ->
        # Use JSON output for consistent error handling
        JsonOutput.deny_pre_tool("Failed to parse hook input JSON")
        |> JsonOutput.write_and_exit()
    end
  end

  defp handle_hook_input(%Claude.Hooks.Events.PreToolUse.Input{
         tool_name: "Bash",
         tool_input: %Claude.Hooks.ToolInputs.Bash{command: command}
       })
       when is_binary(command) do
    if String.contains?(command, "git commit") do
      # Validate before allowing the commit
      validate_commit()
    else
      # Allow non-commit commands
      JsonOutput.allow_pre_tool()
      |> JsonOutput.write_and_exit()
    end
  end

  defp handle_hook_input(_) do
    # Allow tools that aren't Bash or don't have the expected structure
    JsonOutput.allow_pre_tool()
    |> JsonOutput.write_and_exit()
  end

  defp validate_commit do
    Helpers.in_project_dir(nil, fn ->
      with :ok <- check_formatting(),
           :ok <- check_compilation(),
           :ok <- check_unused_dependencies() do
        # All checks passed - allow the commit
        JsonOutput.allow_pre_tool("Pre-commit checks passed")
        |> JsonOutput.write_and_exit()
      else
        {:error, reason} ->
          # One or more checks failed - deny the commit
          error_message = format_error_message(reason)

          JsonOutput.deny_pre_tool(error_message)
          |> JsonOutput.write_and_exit()
      end
    end)
  end

  defp check_formatting do
    case System.cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:error, {:formatting_failed, output}}
    end
  end

  defp check_compilation do
    case System.cmd("mix", ["compile", "--warnings-as-errors"], stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:error, {:compilation_failed, output}}
    end
  end

  defp check_unused_dependencies do
    case System.cmd("mix", ["deps.unlock", "--check-unused"], stderr_to_stdout: true) do
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
