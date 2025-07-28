defmodule Claude.MixProject do
  use Mix.Project

  @version "0.1.0"
  @elixir_version "~> 1.18"
  @description "Opinionated Claude Code integration for Elixir projects"

  def project do
    [
      app: :claude,
      version: @version,
      elixir: @elixir_version,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:jason, "~> 1.4"},
      {:mimic, "~> 1.7", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:igniter, "~> 0.6", optional: true}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bradleygolden/claude"
      },
      maintainers: ["Bradley Golden"],
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md usage-rules.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      source_url: "https://github.com/bradleygolden/claude"
    ]
  end
end
