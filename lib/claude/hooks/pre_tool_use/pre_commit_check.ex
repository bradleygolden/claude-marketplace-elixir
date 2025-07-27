defmodule Claude.Hooks.PreToolUse.PreCommitCheck do
  @moduledoc """
  Pre-commit hook that validates formatting, compilation, tests, and dependencies before allowing commits.

  This hook runs before commit operations and blocks the commit if:
  - Any Elixir files are not properly formatted
  - The project has compilation errors or warnings
  - There are unused dependencies in mix.lock
  - Any tests fail
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
    "Validates formatting, compilation, tests, and dependencies before allowing commits"
  end

  @impl Claude.Hooks.Hook.Behaviour
  def run(:eof) do
    System.halt(0)
  end

  def run(json_input) when is_binary(json_input) do
    case Jason.decode(json_input) do
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
            System.halt(0)

          {:error, _reason} ->
            System.halt(2)
        end
      after
        File.cd!(original_dir)
      end
    else
      System.halt(0)
    end
  end

  defp handle_hook_input(_) do
    System.halt(0)
  end

  defp validate_commit do
    with :ok <- check_formatting(),
         :ok <- check_compilation(),
         :ok <- check_unused_dependencies(),
         :ok <- run_tests() do
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

  defp run_tests do
    IO.puts("Running tests...")

    case System.cmd("mix", ["test"], stderr_to_stdout: true) do
      {_output, 0} ->
        IO.puts("✓ All tests passed")
        :ok

      {output, _exit_code} ->
        IO.puts(:stderr, "\n❌ Tests failed!")
        IO.puts(:stderr, output)
        IO.puts(:stderr, "\nPlease fix failing tests before committing.")
        {:error, :tests_failed}
    end
  end
end
