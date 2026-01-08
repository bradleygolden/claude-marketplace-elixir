defmodule AshProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :ash_project,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:ash, "~> 3.0"},
      {:simple_sat, "~> 0.1"}
    ]
  end
end
