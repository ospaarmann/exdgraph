defmodule ExDgraph.Utils do
  @moduledoc "Common utilities"

  @doc """
  Generate a random string.
  """
  def random_id, do: :rand.uniform() |> Float.to_string() |> String.slice(2..10)

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
    |> Keyword.put_new(:retry_linear_backoff, delay: 150, factor: 2, tries: 3)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end
end
