use Mix.Config

config :ex_dgraph, ExDgraph,
  # default port considered to be: 9080
  hostname: 'localhost',
  pool_size: 5,
  max_overflow: 1,
  # retry the request, in case of error - in the example below the retry will
  # linearly increase the delay from 150ms following a Fibonacci pattern,
  # cap the delay at 15 seconds (the value defined by the default `:timeout`
  # parameter) and giving up after 3 attempts
  retry_linear_backoff: [delay: 150, factor: 2, tries: 3],
  enforce_struct_schema: true

# the `retry_linear_backoff` values above are also the default driver values,
# re-defined here mostly as a reminder
