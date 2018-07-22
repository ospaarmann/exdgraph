defmodule ExDgraph.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_dgraph,
      version: "0.2.0-alpha.5",
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
        :retry,
        :grpc
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:grpc, "~> 0.3.0-alpha.2"},
      {:gun, "1.0.0-pre.5"},
      {:protobuf, "~> 0.5"},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5.1"},
      {:db_connection, "~> 1.1"},
      {:retry, "~> 0.10"},
      {:uuid, "~> 1.1"},
      {:morphix, "~> 0.3"},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false},
      {:excoveralls, "~> 0.9", only: :test},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    A gRPC based Dgraph client for Elixir.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Ole Spaarmann"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/ospaarmann/exdgraph"}
    ]
  end
end
