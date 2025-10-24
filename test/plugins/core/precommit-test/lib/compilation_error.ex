defmodule CompilationError do
  def broken_function do
    undefined_variable + 10
  end

  def another_broken(x) do
    nonexistent_function(x)
  end
end
