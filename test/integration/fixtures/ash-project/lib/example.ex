defmodule AshProject.Example do
  @moduledoc "Example Ash resource for testing"

  use Ash.Resource,
    domain: AshProject.Domain

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false, public?: true)
  end

  actions do
    defaults([:read, :create, :update, :destroy])
  end
end
