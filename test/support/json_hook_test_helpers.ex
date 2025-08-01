defmodule Claude.Test.JsonHookTestHelpers do
  @moduledoc """
  Test helpers for hooks that use JSON output.

  This module provides helpers to make testing hooks with JSON output easier
  by automatically handling System.halt stubbing and JSON parsing.
  """

  import Mimic
  import ExUnit.CaptureIO
  import ExUnit.Assertions

  @doc """
  Setup callback that configures System.halt to return instead of raising.

  This allows hooks using JsonOutput.write_and_exit to work in tests.

  ## Usage

      setup :setup_json_hook_test
      
  Or in an existing setup:

      setup do
        setup_json_hook_test()
        # other setup...
      end
  """
  def setup_json_hook_test(_context \\ %{}) do
    # Override the default trap_unexpected_halts behavior
    # This makes System.halt(0) return {:halt, 0} instead of raising
    stub(System, :halt, fn
      0 -> {:halt, 0}
      code -> raise "Unexpected System.halt(#{code}) called!"
    end)

    :ok
  end

  @doc """
  Captures and parses JSON output from a hook.

  ## Examples

      {json, result} = capture_json_output(fn ->
        MyHook.run(input)
      end)
      
      assert json["decision"] == "block"
      assert json["reason"] =~ "error"
      assert result == :ok
  """
  def capture_json_output(fun) do
    output = capture_io(fun)

    case Jason.decode(output) do
      {:ok, json} ->
        # Hook should return :ok after outputting JSON
        result = fun.()
        {json, result}

      {:error, _} ->
        # If no JSON was output, just return the raw output
        {output, fun.()}
    end
  end

  @doc """
  Runs a hook and captures its JSON output without executing twice.

  This is more efficient than capture_json_output when you don't need 
  the return value.

  ## Examples

      json = run_and_capture_json(fn ->
        MyHook.run(input)
      end)
      
      assert json["decision"] == "block"
  """
  def run_and_capture_json(fun) do
    output = capture_io(fun)

    case Jason.decode(output) do
      {:ok, json} -> json
      {:error, _} -> raise "Expected JSON output but got: #{inspect(output)}"
    end
  end

  @doc """
  Asserts that a hook outputs success JSON.

  ## Examples

      assert_json_success(fn ->
        MyHook.run(valid_input)
      end)
  """
  def assert_json_success(fun) do
    json = run_and_capture_json(fun)
    assert json["continue"] == true
    json
  end

  @doc """
  Asserts that a hook outputs a blocking decision.

  ## Examples

      assert_json_block(fn ->
        MyHook.run(invalid_input)
      end, "compilation error")
  """
  def assert_json_block(fun, expected_reason_pattern \\ nil) do
    json = run_and_capture_json(fun)
    assert json["decision"] == "block"

    if expected_reason_pattern do
      assert json["reason"] =~ expected_reason_pattern
    end

    json
  end
end
