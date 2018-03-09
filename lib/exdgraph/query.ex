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

  @doc """
  Runs a query agains the database. Either returns {:ok, result} or {:error, error}
  """
  def query(conn, statement) do
    case query_commit(conn, statement) do
      {:error, f} -> {:error, code: f.code, message: f.message}
      r -> {:ok, r}
    end
  end

  @doc """
  Runs a query agains the database. Either returns {:ok, result} or {:error, error}
  """
  def query(conn, search_type, predicate, object, display) do
    if display != "expand(_all_)" do
      display = "vertex_type " <> display
    end

    query = """
    { nodes(func: #{search_type}(#{predicate}, \"#{object}\")) { #{display} } }
    """

    query(conn, query)
  end

  @doc """
  Runs a query agains the database. Either returns {:ok, result} or {:error, error}
  """
  def query(conn, search_type, predicate, object) do
    query(conn, search_type, predicate, object, "expand(_all_)")
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
