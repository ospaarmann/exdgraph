defmodule ExDgraph.Query do
  @moduledoc """
  Provides the functions for the callbacks from the DBConnection behaviour.
  """
  alias ExDgraph.{Exception, QueryStatement, Transform}

  @doc false
  def query(conn, statement) do
    case query_commit(conn, statement) do
      {:error, f} -> {:error, code: Map.get(f, :code, Map.get(f, :status)), message: f.message}
      r -> {:ok, r}
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
    exec = fn conn ->
      q = %QueryStatement{statement: statement}

      case DBConnection.execute(conn, q, %{}) do
        {:ok, resp} -> Transform.transform_query(resp)
        other -> other
      end
    end
    DBConnection.run(conn, exec, run_opts())
  end

  defp run_opts do
    [pool: ExDgraph.config(:pool), timeout: ExDgraph.config(:timeout)]
  end
end
