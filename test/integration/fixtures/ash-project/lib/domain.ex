defmodule AshProject.Domain do
  @moduledoc "Example Ash domain for testing"

  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource(AshProject.Example)
  end
end
