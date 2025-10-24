defmodule Calculator do
  @moduledoc """
  Simple calculator module for testing.
  """

  def add(a, b) do
    a + b
  end

  def subtract(a, b) do
    a - b
  end

  def multiply(a, b) do
    a * b
  end

  def divide(_a, 0) do
    {:error, :division_by_zero}
  end

  def divide(a, b) do
    {:ok, a / b}
  end
end
