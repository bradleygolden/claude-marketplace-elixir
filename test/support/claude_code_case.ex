defmodule Claude.ClaudeCodeCase do
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
  import Mimic

  using opts do
    async = Keyword.get(opts, :async, false)
    trap_halts = Keyword.get(opts, :trap_halts, true)
    setup_project = Keyword.get(opts, :setup_project?, false)
    setup_phx_project = Keyword.get(opts, :setup_phx_project?, false)

    quote do
      use ExUnit.Case, async: unquote(async)
      use Mimic

      import ExUnit.CaptureIO

      import Claude.ClaudeCodeCase,
        only: [
          test_project: 0,
          test_project: 1,
          phx_test_project: 0,
          phx_test_project: 1,
          setup_test_directory: 1,
          setup_test_project: 1,
          setup_phoenix_project: 1,
          trap_unexpected_halts: 0,
          trap_unexpected_halts: 1,
          put_in_config: 3
        ]

      setup :set_mimic_from_context

      if unquote(trap_halts) do
        setup :trap_unexpected_halts
      end

      setup :setup_test_directory

      if unquote(setup_project) do
        setup :setup_test_project
      end

      if unquote(setup_phx_project) do
        setup :setup_phoenix_project
      end
    end
  end

  setup _tags do
    :ok
  end

  @doc """
  Setup callback that traps unexpected System.halt calls.

  Use this as a setup callback to catch unexpected System.halt calls:

      setup :trap_unexpected_halts

  Or in an existing setup block:

      setup do
        trap_unexpected_halts()
        # other setup...
        :ok
      end

  Then in specific tests, you can override with expect/stub for expected halts:

      test "handles expected halt" do
        expect(System, :halt, fn 0 -> :ok end)
        MyModule.function_that_halts()
      end
  """
  def trap_unexpected_halts(_context \\ %{}) do
    try do
      stub(System, :halt, fn
        0 ->
          :ok

        exit_code ->
          raise "Unexpected System.halt(#{exit_code}) called! " <>
                  "If this is expected, add `expect(System, :halt, fn #{exit_code} -> :ok end)` to your test."
      end)
    rescue
      ArgumentError -> :ok
    end

    :ok
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
        inputs: ["**/*.{ex,exs}", "{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
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
        inputs: ["**/*.{ex,exs}", "{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
      ]
      """
    }

    files = Map.merge(default_files, Keyword.get(opts, :files, %{}))
    opts = Keyword.put(opts, :files, files)

    Igniter.Test.phx_test_project(opts)
  end

  def setup_test_directory(_context) do
    test_dir = Path.join(System.tmp_dir!(), "claude_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(test_dir)

    on_exit(fn ->
      File.rm_rf!(test_dir)
    end)

    {:ok, test_dir: test_dir}
  end

  @doc """
  Setup function that creates and applies a test project in the test directory.

  This is called automatically when using:
      use Claude.Test.ClaudeCodeCase, setup_project?: true
  """
  def setup_test_project(context) do
    test_dir = context.test_dir

    # Stub System.get_env to return test_dir for CLAUDE_PROJECT_DIR
    stub(System, :get_env, fn
      "CLAUDE_PROJECT_DIR" -> test_dir
      key -> System.get_env(key)
    end)

    # Create and apply the Igniter project (keeps files in memory)
    project_files = context[:project_files] || %{}

    igniter =
      test_project(files: project_files)
      |> Igniter.Test.apply_igniter!()

    # Write the test files to disk
    write_test_files(igniter, test_dir)

    # Compile if requested (default: false for tests)
    if context[:compile_project] do
      System.cmd("mix", ["compile"], cd: test_dir)
    end

    {:ok, project_dir: test_dir}
  end

  defp write_test_files(igniter, base_dir) do
    # Get the test files from the igniter
    test_files = igniter.assigns[:test_files] || %{}

    # Write each file to disk
    Enum.each(test_files, fn {path, content} ->
      full_path = Path.join(base_dir, path)
      dir = Path.dirname(full_path)
      File.mkdir_p!(dir)
      File.write!(full_path, content)
    end)
  end

  @doc """
  Setup function that creates and applies a Phoenix test project in the test directory.

  This is called automatically when using:
      use Claude.Test.ClaudeCodeCase, setup_phx_project?: true
  """
  def setup_phoenix_project(context) do
    test_dir = context.test_dir

    # Stub System.get_env to return test_dir for CLAUDE_PROJECT_DIR
    stub(System, :get_env, fn
      "CLAUDE_PROJECT_DIR" -> test_dir
      key -> System.get_env(key)
    end)

    # Create and apply the Igniter Phoenix project (keeps files in memory)
    project_files = context[:project_files] || %{}

    igniter =
      phx_test_project(files: project_files)
      |> Igniter.Test.apply_igniter!()

    # Write the test files to disk
    write_test_files(igniter, test_dir)

    # Compile if requested (default: false for tests)
    if context[:compile_project] do
      System.cmd("mix", ["compile"], cd: test_dir)
    end

    {:ok, project_dir: test_dir}
  end

  @doc """
  Put a value into the claude.exs file at the specified path and key.
  """
  def put_in_config(path, key, value) do
    config_path = Path.join(path, ".claude.exs")

    config =
      if File.exists?(config_path) do
        try do
          {config, _bindings} = Code.eval_file(config_path)
          config
        rescue
          _ -> %{}
        end
      else
        %{}
      end

    updated_config = put_in(config, key, value)
    formatted_config = inspect(updated_config, pretty: true, limit: :infinity)
    File.write!(config_path, formatted_config)

    updated_config
  end
end
