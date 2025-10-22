defmodule TestCompile do
  def unused_function(x) do
    x + 1
  end

  defp square(n) do
    n * n
  end
end
