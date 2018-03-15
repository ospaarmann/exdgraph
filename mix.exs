defmodule ExDgraph.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dgraph,
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
      docs: [main: "ExDgraph", extras: ["README.md"]],
      # ExCoveralls
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [
        :logger,
        :poolboy,
        :db_connection,
        :retry
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:grpc, github: "tony612/grpc-elixir"},
      {:protobuf, "~> 0.5"},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5.1"},
      {:db_connection, "~> 1.1"},
      {:retry, "~> 0.8"},
      {:uuid, "~> 1.1"},
      {:morphix, "~> 0.2.1"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.5", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test}
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
