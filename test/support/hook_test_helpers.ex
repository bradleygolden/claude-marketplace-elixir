defmodule Claude.Test.HookTestHelpers do
  @moduledoc """
  Helper functions for testing hooks that use exit codes.
  """

  import ExUnit.Assertions
  import ExUnit.CaptureIO
  import Mimic

  # Runs a hook and captures its exit behavior.
  # Returns:
  # - {:exit, 0, stdout, stderr} for successful exit
  # - {:exit, 2, stdout, stderr} for error exit
  # - {:error, reason} if something goes wrong
  defp run_hook_with_exit(hook_module, input) do
    json_input =
      case input do
        input when is_binary(input) -> input
        input -> Jason.encode!(input)
      end

    # Expect the halt and capture its value
    expect(System, :halt, fn code ->
      send(self(), {:halt_called, code})
      :ok
    end)

    # Capture stderr using CaptureIO
    output =
      capture_io(:stderr, fn ->
        # Also capture stdout
        stdout =
          capture_io(fn ->
            hook_module.run(json_input)
          end)

        send(self(), {:stdout, stdout})
      end)

    # Get stdout from the message
    stdout =
      receive do
        {:stdout, s} -> s
      after
        100 -> ""
      end

    # Get the exit code from the message
    receive do
      {:halt_called, code} -> {:exit, code, stdout, output}
    after
      100 -> {:error, :no_halt_called}
    end
  end

  @doc """
  Asserts that a hook exits successfully (code 0) with no output.
  """
  def assert_hook_success(hook_module, input) do
    case run_hook_with_exit(hook_module, input) do
      {:exit, 0, "", ""} ->
        :ok

      {:exit, 0, stdout, stderr} ->
        flunk(
          "Expected silent success but got stdout: #{inspect(stdout)}, stderr: #{inspect(stderr)}"
        )

      {:exit, code, _, stderr} ->
        flunk("Expected exit code 0 but got #{code} with stderr: #{stderr}")

      {:error, reason} ->
        flunk("Hook failed: #{inspect(reason)}")
    end
  end

  @doc """
  Asserts that a hook exits with error (code 2) and returns the stderr message.
  """
  def assert_hook_error(hook_module, input) do
    case run_hook_with_exit(hook_module, input) do
      {:exit, 2, "", stderr} when stderr != "" ->
        stderr

      {:exit, 2, stdout, ""} ->
        flunk("Expected stderr output but got stdout: #{inspect(stdout)}")

      {:exit, 0, _, _} ->
        flunk("Expected exit code 2 but hook succeeded")

      {:exit, code, _, stderr} ->
        flunk("Expected exit code 2 but got #{code} with stderr: #{stderr}")

      {:error, reason} ->
        flunk("Hook failed: #{inspect(reason)}")
    end
  end
end
