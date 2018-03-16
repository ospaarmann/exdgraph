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
  def query(conn, search_type, predicate_object, select \\ "expand(_all_)") do
    if select != "expand(_all_)" do
      select = "vertex_type " <> select
    end

    if is_tuple(predicate_object) do
      predicate = elem(predicate_object, 0)
      object = elem(predicate_object, 1)

      query = """
      { nodes(func: #{search_type}(#{predicate}, \"#{object}\")) { #{select} } }
      """
    else
      query = """
      { nodes(func: #{search_type}(\"#{predicate_object}\")) { #{select} } }
      """
    end

    query(conn, query)
  end

  @doc """
  Runs a query agains the database. Either returns {:ok, result} or {:error, error}
  """
  # def query(conn, search_type, predicate, object) do
  #   query(conn, search_type, predicate, object, "expand(_all_)")
  # end

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
