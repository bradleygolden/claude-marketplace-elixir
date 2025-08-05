defmodule TestPrecommit do
  def badly_formatted() do
    _unused_var = 42
    :ok
  end
end
