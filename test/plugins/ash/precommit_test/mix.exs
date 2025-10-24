defmodule PrecommitTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :precommit_test,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      consolidate_protocols: Mix.env() != :dev,
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {PrecommitTest.Application, []}
    ]
  end

  defp deps do
    [
      {:sourceror, "~> 1.8", only: [:dev, :test]},
      {:ash_sqlite, "~> 0.2"},
      {:ash, "~> 3.0"},
      {:igniter, "~> 0.6", only: [:dev, :test]}
    ]
  end

  defp aliases() do
    [test: ["ash.setup --quiet", "test"]]
  end

  defp elixirc_paths(:test),
    do: elixirc_paths(:dev) ++ ["test/support"]

  defp elixirc_paths(_),
    do: ["lib"]
end
