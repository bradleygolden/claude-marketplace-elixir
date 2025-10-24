defmodule PrecommitTest.Blog do
  @moduledoc """
  The Blog domain.
  """

  use Ash.Domain

  resources do
    resource PrecommitTest.Blog.Post
  end
end
