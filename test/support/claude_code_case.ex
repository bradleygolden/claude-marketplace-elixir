defmodule Claude.Test.ClaudeCodeCase do
  @moduledoc """
  Base ExUnit case template for Claude tests.

  This module provides common test functionality including:
  - Automatic System.halt trapping to prevent test suite crashes
  - Mimic setup for mocking
  - Common test helpers
  - Project isolation to prevent interference from the actual project's .claude.exs

  ## Usage

      defmodule MyTest do
        use Claude.Test.ClaudeCodeCase

        test "my test" do
          # System.halt will raise unless explicitly stubbed
        end
      end

  ## Options

  You can pass options when using this case:

      use Claude.Test.ClaudeCodeCase, async: true

  Supported options:
  - `:async` - Whether tests in this module can run concurrently (default: false)
  - `:trap_halts` - Whether to trap System.halt calls (default: true)

  ## Project Isolation

  Each test gets its own isolated test directory to prevent interference from the
  actual project's .claude.exs file.

  The test directory is available in your tests as `:test_dir`:

      test "my test", %{test_dir: test_dir} do
        # test_dir is the isolated directory for this test
      end

  ## Overriding System.halt behavior

  By default, any System.halt call will raise an error. You can override this:

      test "expected halt" do
        expect(System, :halt, fn 0 -> :ok end)
        assert :ok = System.halt(0)
      end
  """

  use ExUnit.CaseTemplate

  using opts do
    async = Keyword.get(opts, :async, false)
    trap_halts = Keyword.get(opts, :trap_halts, true)

    quote do
      use ExUnit.Case, async: unquote(async)
      use Mimic

      import ExUnit.CaptureIO
      import Claude.Test.SystemHaltHelpers
      import Claude.TestHelpers

      import Claude.Test.ClaudeCodeCase,
        only: [
          isolate_project: 1,
          cmd: 1,
          cmd: 2,
          test_project: 0,
          test_project: 1,
          phx_test_project: 0,
          phx_test_project: 1
        ]

      setup :set_mimic_from_context

      if unquote(trap_halts) do
        setup :trap_unexpected_halts
      end
    end
  end

  setup _tags do
    test_isolation_dir =
      Path.join(System.tmp_dir!(), "claude_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(test_isolation_dir)

    on_exit(fn ->
      File.rm_rf!(test_isolation_dir)
    end)

    {:ok, test_dir: test_isolation_dir}
  end

  @doc """
  Setup helper that provides an isolated test directory.

  Use this in tests that need project isolation:

      setup :isolate_project

  Or in combination with other setup:

      setup [:isolate_project, :other_setup]
  """
  def isolate_project(%{test_dir: _test_dir}) do
    # Project isolation is now handled by test_dir setup
    :ok
  end

  @doc """
  Execute a command using Elixir ports with optional stdin input.

  ## Examples

      # Simple command
      {output, 0} = cmd("echo 'hello'")
      assert output == "hello\\n"
      
      # Command with stdin
      {output, 0} = cmd("cat", stdin: "Hello from stdin")
      assert output == "Hello from stdin"
      
      # Command that fails
      {output, exit_code} = cmd("exit 1")
      assert exit_code == 1

  ## Options

  - `:stdin` - String to send to the command's stdin
  - `:cd` - Directory to run the command in
  - `:env` - Environment variables as a list of {"key", "value"} tuples

  ## Returns

  Returns a tuple of `{output, exit_code}` where:
  - `output` is the combined stdout and stderr as a string
  - `exit_code` is the integer exit code of the command
  """
  def cmd(command, opts \\ []) do
    stdin = Keyword.get(opts, :stdin)
    cd = Keyword.get(opts, :cd)
    env = Keyword.get(opts, :env, [])

    # Build port options
    port_opts = [:binary, :exit_status, :stderr_to_stdout, :hide]

    # Add cd option if provided
    port_opts = if cd, do: [{:cd, cd} | port_opts], else: port_opts

    # Convert environment variables to the format expected by Port.open
    port_opts =
      if env != [] do
        env_charlists =
          Enum.map(env, fn {k, v} ->
            {String.to_charlist(k), String.to_charlist(v)}
          end)

        [{:env, env_charlists} | port_opts]
      else
        port_opts
      end

    # For stdin handling, we need to modify the command to use echo/printf
    final_command =
      if stdin do
        # Use printf to preserve exact formatting and handle special characters
        escaped_stdin =
          stdin
          |> String.replace("\\", "\\\\")
          |> String.replace("\"", "\\\"")
          |> String.replace("$", "\\$")
          |> String.replace("`", "\\`")
          |> String.replace("\n", "\\n")

        "printf \"#{escaped_stdin}\" | #{command}"
      else
        command
      end

    # Use sh -c to run the command for consistent shell behavior
    port = Port.open({:spawn, "sh -c '#{escape_shell_arg(final_command)}'"}, port_opts)

    # Collect output
    collect_port_output(port, "")
  end

  defp escape_shell_arg(arg) do
    # Escape single quotes for shell safety
    String.replace(arg, "'", "'\"'\"'")
  end

  defp collect_port_output(port, acc) do
    receive do
      {^port, {:data, data}} ->
        # Continue collecting data
        collect_port_output(port, acc <> data)

      {^port, {:exit_status, status}} ->
        # Command finished with exit status
        {acc, status}
    after
      5000 ->
        # Timeout after 5 seconds
        Port.close(port)
        {acc <> "\n[Command timed out after 5s]", 124}
    end
  end

  @doc """
  Creates an Igniter test project with a default .formatter.exs file.

  This wraps Igniter.Test.test_project/1 and ensures a .formatter.exs file
  is always present to avoid errors in newer versions of Igniter.
  """
  def test_project(opts \\ []) do
    default_files = %{
      ".formatter.exs" => """
      [
        inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
      ]
      """
    }

    files = Map.merge(default_files, Keyword.get(opts, :files, %{}))
    opts = Keyword.put(opts, :files, files)

    Igniter.Test.test_project(opts)
  end

  @doc """
  Creates an Igniter test project simulating a Phoenix project.

  This wraps Igniter.Test.phx_test_project/1 and ensures a .formatter.exs file
  is always present to avoid errors in newer versions of Igniter.
  """
  def phx_test_project(opts \\ []) do
    default_files = %{
      ".formatter.exs" => """
      [
        inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
      ]
      """
    }

    files = Map.merge(default_files, Keyword.get(opts, :files, %{}))
    opts = Keyword.put(opts, :files, files)

    Igniter.Test.phx_test_project(opts)
  end
end
