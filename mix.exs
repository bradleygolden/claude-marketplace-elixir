defmodule Claude.MixProject do
  use Mix.Project

  @version "0.5.2"
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
      docs: docs(),
      dialyzer: dialyzer()
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
      {:req, "~> 0.5", optional: true},
      {:pythonx, "~> 0.4", optional: true},
      {:plug, "~> 1.0", only: :test},
      {:mimic, "~> 1.7", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:igniter, "~> 0.6", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
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
        ~w(lib priv .formatter.exs mix.exs documentation/guide-quickstart.md documentation/guide-hooks.md documentation/guide-mcp.md documentation/guide-usage-rules.md README.md LICENSE CHANGELOG.md usage-rules.md usage-rules)
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:mix, :ex_unit]
    ]
  end

  defp docs do
    [
      main: "guide-quickstart",
      extras: [
        {"documentation/guide-quickstart.md", title: "Quickstart"},
        {"README.md", title: "Overview"},
        {"documentation/guide-hooks.md", title: "Hooks Guide"},
        {"documentation/guide-mcp.md", title: "MCP Servers Guide"},
        {"documentation/guide-usage-rules.md", title: "Usage Rules Guide"},
        {"CHANGELOG.md", title: "Changelog"},
        {"LICENSE", title: "License"},
        {"cheatsheets/hooks.cheatmd", title: "Hooks Cheatsheet"},
        {"cheatsheets/mcp.cheatmd", title: "MCP Cheatsheet"},
        {"cheatsheets/usage-rules.cheatmd", title: "Usage Rules Cheatsheet"}
      ],
      groups_for_extras: [
        "Getting Started": ["documentation/guide-quickstart.md", "README.md"],
        Guides: [
          "documentation/guide-hooks.md",
          "documentation/guide-mcp.md",
          "documentation/guide-usage-rules.md"
        ],
        Cheatsheets: [
          "cheatsheets/hooks.cheatmd",
          "cheatsheets/mcp.cheatmd",
          "cheatsheets/usage-rules.cheatmd"
        ],
        Meta: ["CHANGELOG.md", "LICENSE"]
      ],
      source_ref: "v#{@version}",
      source_url: "https://github.com/bradleygolden/claude"
    ]
  end
end
