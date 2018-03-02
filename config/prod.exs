use Mix.Config

# Application.put_env(:elixir, :ansi_enabled, true)
config :elixir, ansi_enabled: true

# Print only warnings and errors during test
config :logger, level: :warn

config :logger, :console,
  format: "💎  [$level] $date $time  $levelpad$message\n",
  # metadata: [:module, :function, :my_id],
  metadata: [:function, :my_id],
  colors: [
    warn: IO.ANSI.color(172),
    info: IO.ANSI.color(229),
    error: IO.ANSI.color(196),
    debug: IO.ANSI.color(153)
  ]

# Dgraph 
config :exdgraph,
  dgraphServerHTTP: "http://localhost:8080",
  dgraphServerGRPC: "http://localhost:9080"
