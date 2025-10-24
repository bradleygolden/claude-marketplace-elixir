defmodule PrecommitTest.Blog.Post do
  @moduledoc """
  A blog post resource for testing ash.codegen hooks.
  """

  use Ash.Resource,
    domain: PrecommitTest.Blog,
    data_layer: AshSqlite.DataLayer

  sqlite do
    repo PrecommitTest.Repo
    table "posts"
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      accept [:title, :body]
    end

    update :update do
      accept [:title, :body]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :body, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end
end
