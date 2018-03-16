defmodule ExDgraph.Utils do
  @moduledoc "Common utilities"

  @doc """
  Fills in the given `opts` with default options.
  """
  @spec default_config(Keyword.t()) :: Keyword.t()
  def default_config(config \\ Application.get_env(:ex_dgraph, ExDgraph)) do
    config
    |> Keyword.put_new(:hostname, System.get_env("DGRAPH_HOST") || 'localhost')
    |> Keyword.put_new(:port, System.get_env("DGRAPH_PORT") || 9080)
    |> Keyword.put_new(:pool_size, 5)
    |> Keyword.put_new(:max_overflow, 2)
    |> Keyword.put_new(:timeout, 15_000)
    |> Keyword.put_new(:pool, DBConnection.Poolboy)
    |> Keyword.put_new(:ssl, false)
    |> Keyword.put_new(:tls_client_auth, false)
    |> Keyword.put_new(:certfile, nil)
    |> Keyword.put_new(:keyfile, nil)
    |> Keyword.put_new(:cacertfile, nil)
    |> Keyword.put_new(:retry_linear_backoff, delay: 150, factor: 2, tries: 3)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end
end
