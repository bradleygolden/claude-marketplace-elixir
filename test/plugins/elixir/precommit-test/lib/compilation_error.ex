defmodule CompilationError do
  def broken_function do
    undefined_variable + 1
  end
end
