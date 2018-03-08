defmodule ExDgraph.Mutation do
  alias ExDgraph.{Exception, MutationStatement, QueryStatement, Transform}

  def mutation!(conn, statement) do
    case mutation_commit(conn, statement) do
      {:error, f} ->
        raise Exception, code: f.code, message: f.message

      r ->
        r
    end
  end

  def mutation(conn, statement) do
    case mutation_commit(conn, statement) do
      {:error, f} -> {:error, code: f.code, message: f.message}
      r -> {:ok, r}
    end
  end

  defp mutation_commit(conn, statement) do
    exec = fn conn ->
      q = %MutationStatement{statement: statement}

      case DBConnection.execute(conn, q, %{}) do
        {:ok, resp} -> Transform.transform_mutation(resp)
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
