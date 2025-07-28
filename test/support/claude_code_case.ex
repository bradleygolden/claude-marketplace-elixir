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
  actual project's .claude.exs file. `Claude.Core.Project.root/0` is stubbed to 
  return the isolated test directory, which effectively isolates all project-related
  operations including reading .claude.exs and .claude/settings.json.

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

      setup :set_mimic_global

      if unquote(trap_halts) do
        setup :trap_unexpected_halts
      end
    end
  end

  setup _tags do
    # Set up project isolation to prevent the actual project's .claude.exs from interfering
    test_isolation_dir =
      Path.join(System.tmp_dir!(), "claude_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(test_isolation_dir)

    # Stub Claude.Core.Project.root to use our isolated directory
    Mimic.stub(Claude.Core.Project, :root, fn -> test_isolation_dir end)

    # Clean up the test directory after the test
    on_exit(fn ->
      File.rm_rf!(test_isolation_dir)
    end)

    {:ok, test_dir: test_isolation_dir}
  end
end
