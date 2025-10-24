defmodule SobelowPostEditTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :sobelow_postedit_test,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:sobelow, "~> 0.14", only: [:dev, :test], runtime: false}
    ]
  end
end
