defmodule Claude.MixProject do
  use Mix.Project

  @version "0.3.0"
  @elixir_version "~> 1.18"
  @description "Batteries-included Claude Code integration for Elixir projects"

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
      extra_applications: [:logger],
      mod: {Claude.Application, []}
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
      files:
        ~w(lib .formatter.exs mix.exs documentation/quickstart.md documentation/hooks.md documentation/subagents.md documentation/generators.md README.md LICENSE CHANGELOG.md usage-rules.md usage-rules)
    ]
  end

  defp docs do
    [
      main: "quickstart",
      extras: [
        {"documentation/quickstart.md", title: "Quickstart"},
        {"README.md", title: "Overview"},
        {"documentation/hooks.md", title: "Hooks"},
        {"documentation/subagents.md", title: "Sub-Agents"},
        {"documentation/generators.md", title: "Generators"},
        {"CHANGELOG.md", title: "Changelog"},
        {"cheatsheets/hooks.cheatmd", title: "Hook Configuration"}
      ],
      groups_for_extras: [
        "Getting Started": ["documentation/quickstart.md", "README.md"],
        Guides: [
          "documentation/hooks.md",
          "documentation/subagents.md",
          "documentation/generators.md"
        ],
        Cheatsheets: ["cheatsheets/hooks.cheatmd"],
        Meta: ["CHANGELOG.md"]
      ],
      source_ref: "v#{@version}",
      source_url: "https://github.com/bradleygolden/claude"
    ]
  end
end
