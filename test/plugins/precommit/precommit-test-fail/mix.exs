defmodule PrecommitTestFail.MixProject do
  use Mix.Project

  def project do
    [
      app: :precommit_test_fail,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  defp deps do
    []
  end

  defp aliases do
    [
      precommit: ["compile --warnings-as-errors", "deps.unlock --unused", "format", "test"]
    ]
  end
end
