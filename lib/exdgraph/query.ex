defmodule ExDgraph.Query do
  alias ExDgraph.{Exception, QueryStatement, Transform}

  def query!(conn, statement) do
    case query_commit(conn, statement) do
      {:error, f} ->
        raise Exception, code: f.code, message: f.message

      r ->
        r
    end
  end

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
        {:ok, resp} -> Transform.transform(resp)
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
