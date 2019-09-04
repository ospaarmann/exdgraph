defmodule ExDgraph.Query do
  @moduledoc """
  Provides the functions for the callbacks from the DBConnection behaviour.
  """
  alias ExDgraph.{Exception, Query, Transform}

  defstruct statement: ""

  @doc false
  def query(conn, statement) do
    case query_commit(conn, statement) do
      {:error, f} ->
        {:error, code: Map.get(f, :code, Map.get(f, :status)), message: f.message}

      {:ok, %Query{}, result} ->
        {:ok, result}
    end
  end

  @doc false
  def query!(conn, statement) do
    case query(conn, statement) do
      {:ok, r} ->
        r

      {:error, code: code, message: message} ->
        raise Exception, code: code, message: message
    end
  end

  defp query_commit(conn, statement) do
    q = %Query{statement: statement}

    case DBConnection.execute(conn, q, %{}) do
      {:ok, resp} -> Transform.transform_query(resp)
      other -> other
    end
  end

  defp run_opts do
    [pool: ExDgraph.config(:pool), timeout: ExDgraph.config(:timeout)]
  end
end

defimpl DBConnection.Query, for: ExDgraph.Query do
  alias ExDgraph.Transform

  def describe(query, _), do: query

  def parse(query, _), do: query

  def encode(_query, data, _), do: data

  def decode(_query, result, _opts), do: Transform.transform_query(result)
end
