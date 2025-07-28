defmodule ExampleHooks.InvalidHook do
  @moduledoc """
  Example of an invalid hook that doesn't implement the behavior correctly.
  Used for testing hook validation.
  """

  # Intentionally not using the behavior macro
  # Missing required callbacks

  def some_function do
    :ok
  end
end