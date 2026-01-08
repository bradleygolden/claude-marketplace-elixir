defmodule UnusedDepsProject.MixProject do
  use Mix.Project

  def project do
    [
      app: :unused_deps_project,
      version: "0.1.0",
      elixir: "~> 1.14",
      deps: deps()
    ]
  end

  defp deps do
    [
      # This dep is intentionally not used in code - for testing unused deps check
      {:jason, "~> 1.4"}
    ]
  end
end
