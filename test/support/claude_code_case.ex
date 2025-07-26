defmodule Claude.Test.ClaudeCodeCase do
  @moduledoc """
  Base ExUnit case template for Claude tests.

  This module provides common test functionality including:
  - Automatic System.halt trapping to prevent test suite crashes
  - Mimic setup for mocking
  - Common test helpers

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
    # Any common setup that should run for all tests
    # Currently empty, but can be extended in the future
    :ok
  end
end
