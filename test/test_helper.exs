# Logger.configure(level: :info)
ExUnit.start(exclude: [:skip])

defmodule ExDgraph.TestHelper do
end

if Process.whereis(ExDgraph.pool_name()) == nil do
  {:ok, _pid} = ExDgraph.start_link(Application.get_env(:ex_dgraph, ExDgraph))
end

Process.flag(:trap_exit, true)
