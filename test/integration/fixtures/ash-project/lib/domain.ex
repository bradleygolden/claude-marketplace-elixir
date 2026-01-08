defmodule AshProject.Domain do
  @moduledoc "Example Ash domain for testing"

  use Ash.Domain

  resources do
    resource(AshProject.Example)
  end
end
