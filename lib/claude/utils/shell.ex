defmodule Claude.Utils.Shell do
  @moduledoc """
  Shell output utilities for consistent CLI formatting.
  """

  @doc """
  Outputs an informational message.
  """
  def info(message) do
    IO.puts(message)
  end

  @doc """
  Outputs a success message with a checkmark.
  """
  def success(message) do
    IO.puts("✓ #{message}")
  end

  @doc """
  Outputs an error message to stderr.
  """
  def error(message) do
    IO.puts(:stderr, "❌ #{message}")
  end

  @doc """
  Outputs a warning message.
  """
  def warn(message) do
    IO.puts("⚠️  #{message}")
  end

  @doc """
  Outputs a bullet point.
  """
  def bullet(message) do
    IO.puts("  • #{message}")
  end

  @doc """
  Outputs a blank line.
  """
  def blank do
    IO.puts("")
  end
end
