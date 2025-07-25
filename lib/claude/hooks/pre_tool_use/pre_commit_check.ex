defmodule Claude.Hooks.PreToolUse.PreCommitCheck do
  @moduledoc """
  Pre-commit hook that validates formatting and compilation before allowing commits.

  This hook runs before commit operations and blocks the commit if:
  - Any Elixir files are not properly formatted
  - The project has compilation errors or warnings
  """

  @behaviour Claude.Hooks.Hook.Behaviour

  @impl Claude.Hooks.Hook.Behaviour
  def config do
    %Claude.Hooks.Hook{
      type: "command",
      command: "cd $CLAUDE_PROJECT_DIR && mix claude hooks run pre_tool_use.pre_commit_check",
      matcher: "Bash"
    }
  end

  @impl Claude.Hooks.Hook.Behaviour
  def description do
    "Validates formatting and compilation before allowing commits"
  end

  @impl Claude.Hooks.Hook.Behaviour
  def run(_tool_name, _json_params) do
    # Read the hook input from stdin as per the documentation
    input = IO.read(:stdio, :eof)

    case Jason.decode(input) do
      {:ok, hook_data} ->
        handle_hook_input(hook_data)

      {:error, _} ->
        IO.puts(:stderr, "Failed to parse hook input JSON")
        System.halt(1)
    end
  end

  defp handle_hook_input(%{"tool_name" => "Bash", "tool_input" => %{"command" => command}})
       when is_binary(command) do
    if String.contains?(command, "git commit") do
      IO.puts("Pre-commit validation triggered for: #{command}")

      project_dir = System.get_env("CLAUDE_PROJECT_DIR") || File.cwd!()
      original_dir = File.cwd!()

      try do
        File.cd!(project_dir)

        case validate_commit() do
          :ok ->
            # Allow the commit
            System.halt(0)

          {:error, _reason} ->
            # Block the commit - exit code 2 tells Claude to block the tool call
            System.halt(2)
        end
      after
        File.cd!(original_dir)
      end
    else
      # Not a git commit, allow the command
      System.halt(0)
    end
  end

  defp handle_hook_input(_) do
    # Not a Bash tool or missing expected fields, allow it
    System.halt(0)
  end

  defp validate_commit do
    with :ok <- check_formatting(),
         :ok <- check_compilation() do
      :ok
    end
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
end
