defmodule PrecommitTestTest do
  use ExUnit.Case
  doctest PrecommitTest

  test "greets the world" do
    assert PrecommitTest.hello() == :world
  end
end
