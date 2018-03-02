use Mix.Config

# Application.put_env(:elixir, :ansi_enabled, true)
config :elixir, ansi_enabled: true

# Print only warnings and errors during test
config :logger, level: :debug

# Logger.debug "💡 struct_name #{inspect struct_name}", [my_id: 1234]
config :logger, :console,
  format: "🛡  $metadata\n\t$message\n",
  # metadata: [:module, :function, :my_id],
  metadata: [:module, :function, :my_id],
  colors: [
    warn: IO.ANSI.color(172),
    info: IO.ANSI.color(229),
    error: IO.ANSI.color(196),
    debug: IO.ANSI.color(153)
  ]

# Dgraph
#
# docker-compose(alternate) with 3 dgraph instances
# dgraphServerGRPC: 
#   test: "localhost:9082", 
#   dev: "http://localhost:9081", 
#   prod: "http://localhost:9080"
#   dgraph-ratel -port 8088
#
# docker-compose with 1 dgraph instances
# dgraphServerGRPC: 
#   test,dev,prod: "localhost:9080", 
#   dgraph-ratel -port 8080
#
config :exdgraph,
  dgraphServerHTTP: "http://localhost:8082",
  dgraphServerGRPC: "localhost:9082"
