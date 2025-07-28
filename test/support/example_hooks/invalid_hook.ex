defmodule ExampleHooks.InvalidHook do
  @moduledoc """
  Example of an invalid hook that doesn't implement the behavior correctly.
  Used for testing hook validation.
  """

  def some_function do
    :ok
  end
end