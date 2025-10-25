defmodule CalculatorTest do
  use ExUnit.Case
  doctest Calculator

  test "adds two numbers" do
    assert Calculator.add(2, 3) == 5
  end

  test "subtracts two numbers" do
    assert Calculator.subtract(5, 3) == 2
  end

  test "multiplies two numbers" do
    assert Calculator.multiply(4, 3) == 12
  end

  test "divides two numbers" do
    assert Calculator.divide(10, 2) == {:ok, 5.0}
  end

  test "handles division by zero" do
    assert Calculator.divide(10, 0) == {:error, :division_by_zero}
  end

  # Intentionally failing test for testing the hook
  test "this test will fail" do
    assert Calculator.add(2, 2) == 5
  end
end
