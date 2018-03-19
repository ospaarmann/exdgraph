defmodule ExDgraph.Query do
  @moduledoc """
  Provides the functions for the callbacks from the DBConnection behaviour.
  """
  alias ExDgraph.{Exception, QueryStatement, Transform}

  @doc false
  def query!(conn, statement) do
    case query_commit(conn, statement) do
      {:error, f} ->
        raise Exception, code: f.code, message: f.message

      r ->
        r
    end
  end

  @doc false
  def query(conn, statement) do
    case query_commit(conn, statement) do
      {:error, f} -> {:error, code: f.code, message: f.message}
      r -> {:ok, r}
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

    # Response.transform(DBConnection.run(conn, exec, run_opts()))
    DBConnection.run(conn, exec, run_opts())
  end

  defp run_opts do
    [pool: ExDgraph.config(:pool)]
  end
end
