defmodule ValidDocs do
  @moduledoc """
  A module with valid documentation for testing ExDoc plugin.

  This module demonstrates proper documentation that should pass
  ExDoc validation without warnings.
  """

  @doc """
  Adds two numbers together.

  ## Examples

      iex> ValidDocs.add(1, 2)
      3

  """
  @spec add(integer(), integer()) :: integer()
  def add(a, b) do
    a + b
  end

  @doc """
  Multiplies two numbers.

  ## Examples

      iex> ValidDocs.multiply(3, 4)
      12

  """
  @spec multiply(integer(), integer()) :: integer()
  def multiply(a, b) do
    a * b
  end
end
