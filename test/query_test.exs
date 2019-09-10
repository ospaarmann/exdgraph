defmodule ExDgraph.QueryTest do
  @moduledoc false

  use ExUnit.Case
  import ExDgraph.TestHelper
  alias ExDgraph.{Error, Query, QueryResult}

  @sample_query """
    {
        starwars(func: anyofterms(name, "VI"))
        {
          uid
          name
          release_date
          starring
          {
            name
          }
        }
    }
  """

  setup_all do
    {:ok, conn} = ExDgraph.start_link()
    ExDgraph.alter(conn, %{drop_all: true})
    import_starwars_sample(conn)

    [conn: conn]
  end

  test "query/3 with correct query returns {:ok, %Query{}, %Result{}}", %{conn: conn} do
    {status, %Query{} = _query, %QueryResult{} = result} = ExDgraph.query(conn, @sample_query)
    assert status == :ok
    data = result.data
    starwars = List.first(data.starwars)
    assert starwars.name == "Star Wars: Episode VI - Return of the Jedi"
    assert starwars.release_date == "1983-05-25"
    assert length(starwars.starring) == 3
  end

  test "query/3 with wrong query returns {:error, %Error{}}", %{conn: conn} do
    {status, %Error{} = error} = ExDgraph.query(conn, "wrong")
    assert status == :error

    assert %Error{} = error
    assert error.code == 2
    assert error.action == :query
    assert error.reason =~ "Invalid operation type: wrong"
  end

  test "query!/2 with correct query returns query_msg", %{conn: conn} do
    %QueryResult{} = result = ExDgraph.query!(conn, @sample_query)
    data = result.data
    starwars = List.first(data.starwars)
    assert starwars.name == "Star Wars: Episode VI - Return of the Jedi"
    assert starwars.release_date == "1983-05-25"
    assert length(starwars.starring) == 3
  end

  test "query!/2 raises ExDgraph.Exception", %{conn: conn} do
    assert_raise ExDgraph.Error, fn ->
      ExDgraph.query!(conn, "wrong")
    end
  end
end
