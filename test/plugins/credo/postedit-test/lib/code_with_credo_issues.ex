defmodule CodeWithCredoIssues do
  # Missing @moduledoc - Credo violation!

  def reallyLongFunctionNameThatViolatesNamingConventions(
        parameter_one,
        parameter_two,
        parameter_three
      ) do
    # This is an extremely long line that definitely exceeds the 120 character limit and will trigger Credo's line length warning
    result = parameter_one + parameter_two + parameter_three

    # TODO: This function should be refactored - Credo warns about TODO comments
    if result > 0 do
      if result > 10 do
        if result > 100 do
          # Deep nesting - Credo violation
          :very_large
        else
          :large
        end
      else
        :medium
      end
    else
      :small
    end
  end

  def camelCaseFunctionName do
    # Function names should be snake_case - Credo violation (camelCase not snake_case)
    :ok
  end

  def anotherTestFunction do
    # Another CamelCase function name violation
    :another_test
  end
end
