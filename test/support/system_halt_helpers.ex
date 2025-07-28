defmodule Claude.Test.SystemHaltHelpers do
  @moduledoc """
  Test helpers for safely handling System.halt calls in tests.

  This module provides utilities to prevent unexpected System.halt calls
  from killing the test runner.
  """

  import Mimic

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
      stub(System, :halt, fn exit_code ->
        raise "Unexpected System.halt(#{exit_code}) called! " <>
                "If this is expected, add `expect(System, :halt, fn #{exit_code} -> :ok end)` to your test."
      end)
    rescue
      ArgumentError -> :ok
    end

    :ok
  end

  @doc """
  Sets up a stub that allows System.halt but returns a tuple instead of halting.

  This is useful for tests that expect System.halt to be called and want to
  assert on the exit code.

      setup do
        stub_halt_as_return()
        :ok
      end
      
      test "returns correct exit code" do
        assert {:halt, 2} = MyModule.function_that_halts()
      end
  """
  def stub_halt_as_return do
    stub(System, :halt, fn exit_code -> {:halt, exit_code} end)
  end

  @doc """
  Expects a specific System.halt call and returns a value.

      test "halts with specific code" do
        expect_halt(2)
        assert {:halt, 2} = MyModule.function_that_halts()
      end
      
  Note: This will override any previous stub/expect, including trap_unexpected_halts.
  Only the specified exit code will be allowed.
  """
  def expect_halt(expected_code) do
    # First clear any existing stubs to ensure our expect takes precedence
    expect(System, :halt, 1, fn
      ^expected_code ->
        {:halt, expected_code}

      other_code ->
        raise "Unexpected System.halt(#{other_code}) called! Expected System.halt(#{expected_code})."
    end)
  end

  @doc """
  Expects System.halt to be called n times with any exit code.

      test "halts multiple times" do
        expect_halt_times(3)
        MyModule.function_that_halts_three_times()
      end
  """
  def expect_halt_times(n) do
    expect(System, :halt, n, fn exit_code -> {:halt, exit_code} end)
  end
end
