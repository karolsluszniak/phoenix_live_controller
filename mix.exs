defmodule PhoenixLiveController.MixProject do
  use Mix.Project

  @version "0.4.2"

  def project do
    [
      app: :phoenix_live_controller,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description:
        "Controller-style abstraction for building multi-action live views on top of Phoenix.LiveView",
      package: package(),
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_check, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:phoenix_live_view, ">= 0.0.0"},
      {:poison, ">= 0.0.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Karol Słuszniak"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/karolsluszniak/phoenix_live_controller"
      },
      files: ~w(.formatter.exs mix.exs LICENSE.md README.md CHANGELOG.md lib)
    ]
  end

  defp docs do
    [
      main: "Phoenix.LiveController",
      source_ref: "v#{@version}",
      source_url: "https://github.com/karolsluszniak/phoenix_live_controller"
    ]
  end
end
