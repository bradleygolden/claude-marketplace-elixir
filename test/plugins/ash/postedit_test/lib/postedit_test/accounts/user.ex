defmodule PosteditTest.Accounts.User do
  @moduledoc """
  A user resource for testing ash.codegen hooks.
  """

  use Ash.Resource,
    domain: PosteditTest.Accounts,
    data_layer: AshSqlite.DataLayer

  sqlite do
    repo PosteditTest.Repo
    table "users"
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:email, :name]
    end

    update :update do
      accept [:email, :name]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end
end
