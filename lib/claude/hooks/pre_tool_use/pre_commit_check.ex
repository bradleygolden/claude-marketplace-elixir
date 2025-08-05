defmodule Claude.Hooks.PreToolUse.PreCommitCheck do
  @moduledoc """
  Pre-commit hook that validates formatting, compilation, and dependencies before allowing commits.

  This hook runs before commit operations and blocks the commit if:
  - Any Elixir files are not properly formatted
  - The project has compilation errors or warnings
  - There are unused dependencies in mix.lock

  Uses exit codes to communicate with Claude Code:
  - Exit 0: Success (allow the commit)
  - Exit 2: Pre-commit checks failed (block the commit with stderr feedback)
  """

  @doc """
  Pipeline-style pre-commit checker for Claude Code hooks.
  """
  def run(:eof), do: :ok

  def run(input) do
    input
    |> parse_input()
    |> validate_tool()
    |> check_if_commit()
    |> run_pre_commit_checks()
    |> format_response()
    |> output_and_exit()
  end

  defp parse_input(input) do
    case Claude.Hooks.Events.PreToolUse.Input.from_json(input) do
      {:ok, event} ->
        {:ok, event}

      {:error, _} ->
        {:error, "Invalid JSON input"}
    end
  end

  defp validate_tool({:error, _} = error), do: error

  defp validate_tool({:ok, %Claude.Hooks.Events.PreToolUse.Input{tool_name: "Bash"} = input}) do
    {:ok, input}
  end

  defp validate_tool({:ok, _}), do: {:skip, "Not a Bash tool"}

  defp check_if_commit({:error, _} = error), do: error
  defp check_if_commit({:skip, _} = skip), do: skip

  defp check_if_commit(
         {:ok, %Claude.Hooks.Events.PreToolUse.Input{tool_input: tool_input} = input}
       ) do
    case tool_input do
      %{command: command} when is_binary(command) ->
        if String.contains?(command, "git commit") do
          {:ok, input}
        else
          {:skip, "Not a git commit command"}
        end

      _ ->
        {:skip, "No command found"}
    end
  end

  defp run_pre_commit_checks({:error, _} = error), do: error
  defp run_pre_commit_checks({:skip, _} = skip), do: skip

  defp run_pre_commit_checks({:ok, %Claude.Hooks.Events.PreToolUse.Input{cwd: cwd}}) do
    formatting_result = check_formatting(cwd)
    compilation_result = check_compilation(cwd)
    dependencies_result = check_unused_dependencies(cwd)

    case {formatting_result, compilation_result, dependencies_result} do
      {:ok, :ok, :ok} ->
        :all_checks_passed

      _ ->
        failures = []
        failures = if formatting_result != :ok, do: [formatting_result | failures], else: failures

        failures =
          if compilation_result != :ok, do: [compilation_result | failures], else: failures

        failures =
          if dependencies_result != :ok, do: [dependencies_result | failures], else: failures

        {:pre_commit_failed, Enum.reverse(failures)}
    end
  end

  defp check_formatting(project_dir) do
    case System.cmd("mix", ["format", "--check-formatted"],
           cd: project_dir,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:formatting_failed, output}
    end
  end

  defp check_compilation(project_dir) do
    case System.cmd("mix", ["compile", "--warnings-as-errors"],
           cd: project_dir,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:compilation_failed, output}
    end
  end

  defp check_unused_dependencies(project_dir) do
    case System.cmd("mix", ["deps.unlock", "--check-unused"],
           cd: project_dir,
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        :ok

      {output, _exit_code} ->
        {:unused_dependencies, output}
    end
  end

  defp format_response(:all_checks_passed), do: :all_checks_passed
  defp format_response({:skip, _}), do: :skip
  defp format_response({:error, _}), do: :error
  defp format_response({:pre_commit_failed, _} = result), do: result

  defp output_and_exit(:all_checks_passed) do
    System.halt(0)
  end

  defp output_and_exit(:skip) do
    System.halt(0)
  end

  defp output_and_exit(:error) do
    System.halt(0)
  end

  defp output_and_exit({:pre_commit_failed, failures}) do
    IO.puts(
      :stderr,
      "Pre-commit checks failed! Please fix the following issues before committing:"
    )

    IO.puts(:stderr, "")

    Enum.each(failures, &output_failure/1)

    System.halt(2)
  end

  defp output_failure({:formatting_failed, output}) do
    IO.puts(:stderr, "❌ FORMATTING ISSUES DETECTED:")
    IO.puts(:stderr, "")
    IO.puts(:stderr, output)
    IO.puts(:stderr, "")
    IO.puts(:stderr, "→ Run 'mix format' to fix formatting issues")
    IO.puts(:stderr, "")
    IO.puts(:stderr, String.duplicate("-", 60))
    IO.puts(:stderr, "")
  end

  defp output_failure({:compilation_failed, output}) do
    IO.puts(:stderr, "❌ COMPILATION ERRORS DETECTED:")
    IO.puts(:stderr, "")
    IO.puts(:stderr, output)
    IO.puts(:stderr, "")
    IO.puts(:stderr, "→ Fix compilation errors and warnings before committing")
    IO.puts(:stderr, "")
    IO.puts(:stderr, String.duplicate("-", 60))
    IO.puts(:stderr, "")
  end

  defp output_failure({:unused_dependencies, output}) do
    IO.puts(:stderr, "❌ UNUSED DEPENDENCIES DETECTED:")
    IO.puts(:stderr, "")
    IO.puts(:stderr, output)
    IO.puts(:stderr, "")
    IO.puts(:stderr, "→ Run 'mix deps.unlock --unused' to remove unused dependencies")
    IO.puts(:stderr, "")
    IO.puts(:stderr, String.duplicate("-", 60))
    IO.puts(:stderr, "")
  end
end
