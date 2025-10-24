defmodule PosteditTest.Accounts do
  @moduledoc """
  The Accounts domain.
  """

  use Ash.Domain

  resources do
    resource PosteditTest.Accounts.User
  end
end
