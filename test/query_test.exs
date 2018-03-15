defmodule ExDgraph.QueryTest do
  use ExUnit.Case, async: true
  import ExDgraph.TestHelper

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
    conn = ExDgraph.conn()
    drop_all()
    import_starwars_sample()

    on_exit(fn ->
      # close channel ?
      :ok
    end)

    [conn: conn]
  end

  test "query/2 with correct query returns {:ok, query_msg}", %{conn: conn} do
    {status, query_msg} = ExDgraph.Query.query(conn, @sample_query)
    assert status == :ok
    res = query_msg.result
    starwars = res[:starwars]
    one = List.first(starwars)
    assert "Star Wars: Episode VI - Return of the Jedi" == one[:name]
    assert "1983-05-25" == one[:release_date]
  end

  test "query/2 with wrong query returns {:error, error}", %{conn: conn} do
    {status, error} = ExDgraph.Query.query(conn, "wrong")
    assert status == :error
    assert error == [code: 2, message: "while lexing wrong: Invalid operation type: wrong"]
  end

  test "query!/2 with correct query returns query_msg", %{conn: conn} do
    query_msg = ExDgraph.Query.query!(conn, @sample_query)
    res = query_msg.result
    starwars = res[:starwars]
    one = List.first(starwars)
    assert "Star Wars: Episode VI - Return of the Jedi" == one[:name]
    assert "1983-05-25" == one[:release_date]
  end

  test "query!/2 raises ExDgraph.Exception", %{conn: conn} do
    assert_raise ExDgraph.Exception, fn ->
      ExDgraph.Query.query!(conn, "wrong")
    end
  end
end
