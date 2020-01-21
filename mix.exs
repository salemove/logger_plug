defmodule GliaLoggerPlug.MixProject do
  use Mix.Project

  def project do
    [
      app: :glia_logger_plug,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: ~S"""
        A plug that logs every processed HTTP request with single line that
        includes all necessary metadata.
      """,
      package: [
        maintainers: ["Glia TechMovers"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/salemove/logger_plug"}
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.8", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
