use Mix.Config

config :ex_dgraph, ExDgraph,
  # default port considered to be: 9080
  hostname: 'localhost',
  pool_size: 5,
  enforce_struct_schema: false
