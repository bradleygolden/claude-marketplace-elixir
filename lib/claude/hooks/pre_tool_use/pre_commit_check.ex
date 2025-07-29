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

  alias Claude.Hooks.Helpers

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof) do
    :ok
  end

  def run(json_input) when is_binary(json_input) do
    case Claude.Hooks.Events.PreToolUse.Input.from_json(json_input) do
      {:ok, %Claude.Hooks.Events.PreToolUse.Input{} = input} ->
        handle_hook_input(input)

      {:error, _} ->
        IO.puts(:stderr, "Failed to parse hook input JSON")
        {:error, :invalid_json}
    end
  end

  defp handle_hook_input(%Claude.Hooks.Events.PreToolUse.Input{
         tool_name: "Bash",
         tool_input: %Claude.Hooks.ToolInputs.Bash{command: command}
       })
       when is_binary(command) do
    if String.contains?(command, "git commit") do
      IO.puts("Pre-commit validation triggered for: #{command}")
      validate_commit()
    else
      :ok
    end
  end

  defp handle_hook_input(_) do
    :ok
  end

  defp validate_commit do
    Helpers.in_project_dir(nil, fn ->
      with :ok <- check_formatting(),
           :ok <- check_compilation(),
           :ok <- check_unused_dependencies() do
        :ok
      end
    end)
  end

  defp check_formatting do
    IO.puts("Checking code formatting...")

    case System.cmd("mix", ["format", "--check-formatted"], stderr_to_stdout: true) do
      {_output, 0} ->
        IO.puts("✓ Code formatting is correct")
        :ok

      {output, _exit_code} ->
        IO.puts(:stderr, "\n❌ Formatting check failed!")
        IO.puts(:stderr, output)
        IO.puts(:stderr, "\nPlease run 'mix format' to fix formatting issues before committing.")
        {:error, :formatting_failed}
    end
  end

  defp check_compilation do
    IO.puts("Checking compilation...")

    case System.cmd("mix", ["compile", "--warnings-as-errors"], stderr_to_stdout: true) do
      {_output, 0} ->
        IO.puts("✓ Compilation successful")
        :ok

      {output, _exit_code} ->
        IO.puts(:stderr, "\n❌ Compilation check failed!")
        IO.puts(:stderr, output)
        IO.puts(:stderr, "\nPlease fix compilation errors and warnings before committing.")
        {:error, :compilation_failed}
    end
  end

  defp check_unused_dependencies do
    IO.puts("Checking for unused dependencies...")

    case System.cmd("mix", ["deps.unlock", "--check-unused"], stderr_to_stdout: true) do
      {_output, 0} ->
        IO.puts("✓ No unused dependencies found")
        :ok

      {output, _exit_code} ->
        IO.puts(:stderr, "\n❌ Unused dependencies detected!")
        IO.puts(:stderr, output)
        IO.puts(:stderr, "\nPlease run 'mix deps.unlock --unused' to remove unused dependencies.")
        {:error, :unused_dependencies}
    end
  end
end
