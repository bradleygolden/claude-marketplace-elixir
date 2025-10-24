defmodule CodeWithIssues do
  def process_data(input) do
    data = String.trim(input)
    result = data |> String.split(",") |> Enum.map(&String.to_integer/1) |> Enum.sum()
    if result > 0, do: {:ok, result}, else: {:error, "Invalid result"}
  end

  def complex_nested_function(x, y, z) do
    if x > 0 do
      if y > 0 do
        if z > 0 do
          if x > y do
            if y > z do
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
