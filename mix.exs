defmodule ExDgraph.MixProject do
  use Mix.Project

  def project do
    [
      app: :exdgraph,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),

      # Docs
      name: "ExDgraph",
      source_url: "https://github.com/ospaarmann/exdgraph",
      # The main page in the docs
      docs: [main: "ExDgraph", extras: ["README.md"]]
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
      {:grpc, github: "tony612/grpc-elixir"},
      {:protobuf, "~> 0.5"},
      {:poison, "~> 3.1"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    ExDgraph is the attempt to create a gRPC based client for the Dgraph database. WORK IN PROGRESS.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Ole Spaarmann"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ospaarmann/exdgraph"}
    ]
  end
end
