defmodule PrecommitProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :precommit_project,
      version: "0.1.0",
      elixir: "~> 1.14",
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      precommit: ["format --check-formatted", "compile --warnings-as-errors"]
    ]
  end
end
