defmodule CodeWithIssues do
  # Missing @moduledoc is a Credo.Check.Readability.ModuleDoc violation
  
  def ProcessData(input) do
    # Function name should be snake_case (process_data) - Credo.Check.Consistency.ParameterPatternMatching
    data = String.trim(input)
    
    # FIXME: This needs better error handling - Credo warns about FIXME/TODO comments
    result = data |> String.split(",") |> Enum.map(&String.to_integer/1) |> Enum.sum()
    
    # Extremely long line that exceeds 120 characters and will definitely trigger Credo line length warning check
    if result > 0, do: {:ok, result}, else: {:error, "Invalid result because the sum was not positive"}
  end
  
  def complex_nested_function(x, y, z) do
    if x > 0 do
      if y > 0 do
        if z > 0 do
          if x > y do
            if y > z do
              # Too much nesting - Credo.Check.Refactor.Nesting
              :deeply_nested
            else
              :nested
            end
          else
            :nested
          end
        else
          :nested
        end
      else
        :nested
      end
    else
      :not_nested
    end
  end
end
