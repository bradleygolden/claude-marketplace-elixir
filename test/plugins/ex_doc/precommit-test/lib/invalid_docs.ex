defmodule InvalidDocs do
  @moduledoc """
  A module with invalid documentation references for testing ExDoc plugin.

  This should trigger warnings because it references non-existent functions.
  See `NonExistent.function/1` for more details.
  """

  @doc """
  This function has broken references in its documentation.

  It supposedly calls `UndefinedModule.do_something/2` but that doesn't exist.
  Also references `InvalidDocs.missing_function/0` which doesn't exist either.

  ## Examples

      iex> InvalidDocs.broken_example()
      :ok

  """
  def broken_example do
    :ok
  end

  @doc """
  Another function with invalid references.

  This references `AnotherMissingModule.process/1` in the docs.
  """
  def another_broken do
    :ok
  end
end
