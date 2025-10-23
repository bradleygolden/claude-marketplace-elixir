defmodule BrokenCode do
  def has_undefined_variable do
    this_variable_is_undefined
  end

  def calls_undefined_function(x) do
    undefined_function(x)
  end
  
  def another_error do
    some_module_that_does_not_exist.function()
  end
end
