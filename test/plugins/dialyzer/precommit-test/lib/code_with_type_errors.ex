defmodule CodeWithTypeErrors do
  @spec add_numbers(integer(), integer()) :: integer()
  def add_numbers(a, b) do
    # This will cause a type error - returning a string instead of integer
    "#{a + b}"
  end

  @spec get_list() :: list(integer())
  def get_list do
    # This will cause a type error - returning atoms instead of integers
    [:one, :two, :three]
  end

  @spec process_data(map()) :: {:ok, String.t()} | {:error, atom()}
  def process_data(data) do
    # This will cause a type error - returning integer instead of expected types
    42
  end
end
