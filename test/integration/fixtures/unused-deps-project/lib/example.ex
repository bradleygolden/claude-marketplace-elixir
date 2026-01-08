defmodule UnusedDepsProject.Example do
  @moduledoc "Example module - intentionally does NOT use jason dependency"

  def hello do
    :world
  end
end
