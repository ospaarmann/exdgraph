defmodule ExDgraph.QueryBuilderTest do
  @moduledoc """
  """
  use ExUnit.Case
  import ExDgraph.TestHelper
  require Logger
  import ExDgraph
  import ExDgraph.GraphQL
  alias ExDgraph.GraphQL

  @testing_schema "person_id: string @index(exact).
      name: string @index(exact, term) @count .
      gender: string .
      alias_name: [string] .
      is_jedi: bool .
      age: int @index(int) .
      friend: uid @count .
      knows: uid .
      dob: dateTime ."

  setup_all do
    conn = ExDgraph.conn()
    drop_all()
    import_starwars_sample()

    on_exit(fn ->
      :ok
    end)

    [conn: conn]
  end

  test "GraphQL new/1 default name", %{conn: conn} do
    {:ok, graph_query} = GraphQL.new(conn)
    assert "graphql" == graph_query.name
  end

  test "GraphQL new/2 set name", %{conn: conn} do
    {:ok, graph_query} = GraphQL.new(conn, "test_query")
    assert "test_query" == graph_query.name
  end

  test "GraphQL empty query", %{conn: conn} do
    graph_query = GraphQL.new(conn, "test_query")

    {status, error} =
      graph_query
      |> request()

    assert :error == status

    assert [
             code: 2,
             message: "Only aggregation/math functions allowed inside empty blocks. Got: expand"
           ] == error
  end

  test "GraphQL set query_root with :allofterms", %{conn: conn} do
    graph_query = GraphQL.new(conn, "test_query")

    {status, query_result} =
      graph_query
      |> root(:allofterms, {"name", "IV"})
      |> request()

    one = List.first(query_result)
    assert "Star Wars: Episode IV - A New Hope" == one[:name]
  end

  test "GraphQL set query_root with :uid", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.mutation(conn, "_:new <name> \"Duffy\" .")
    uid = mutation_msg[:uids]["new"]

    graph_query = GraphQL.new(conn, "test_query")

    {status, query_result} =
      graph_query
      |> root(:uid, uid)
      |> request()

    one = List.first(query_result)
    assert "Duffy" == one[:name]
  end
  
  test "GraphQL set first: 1", %{conn: conn} do
    graph_query = GraphQL.new(conn, "test_query")

    {status, query_result} =
      graph_query
      |> root(:allofterms, {"name", "Star Wars"})
      |> first(2)
      |> request()

    assert 2 == Enum.count(query_result)
  end

  test "GraphQL set one filter", %{conn: conn} do
    graph_query = GraphQL.new(conn, "test_query")

    {status, query_result} =
      graph_query
      |> root(:allofterms, {"name", "IV"})
      |> request()
  end

  # FIXME: remove
  test "EXPERIMENTAL with" do
    graph_query = GraphQL.new(conn, "test_query")
    {status, query_result} =
    with result <- root(graph_query, :allofterms, {"name", "Star Wars"}),
         result <- first(result, 2) do
      request(result)
    else
      :error ->
        {:error, :wrong_data}
    end
    assert 2 == Enum.count(query_result)
  end

  test "GraphQL", %{conn: conn} do
    graph_query = GraphQL.new(conn, "test_query")
    {status, query_result} = graph_query
    # |> root(:allofterms, {"name", "Star Wars"})
    # |> first(2)
    # |> filter(:has, "genre")
    # |> filter(:or, :le, {"production-cost", "20000000"})
    # |> order(:desc, "initial_release_date")
    # |> return(["uid")
    # |> return(["name", "initial_release_date"])
    # |> return_expand("director.film")
    # |> filter_expand(:le, {initial_release_date, "2000"})
    # |> return_expand(["name@en", "initial_release_date"])
    # |> request()
  end
end
