defmodule MutationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  import ExDgraph.TestHelper

  @map_insert_mutation %{
    name: "Alice",
    identifier: "alice_json",
    friends: %{
      name: "Betty"
    }
  }

  @map_insert_check_query """
    {
        people(func: allofterms(identifier, "alice_json"))
        {
          uid
          name
          friends
          {
            name
          }
        }
    }
  """

  setup do
    conn = ExDgraph.conn()
    drop_all()
    import_starwars_sample()

    on_exit(fn ->
      # close channel ?
      :ok
    end)

    [conn: conn]
  end

  test "mutation/2 returns {:ok, mutation_msg} for correct mutation", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.mutation(conn, starwars_creation_mutation())
    assert status == :ok
    assert mutation_msg.context.aborted == false
  end

  test "mutation/2 returns {:error, error} for incorrect mutation", %{conn: conn} do
    {status, error} = ExDgraph.mutation(conn, "wrong")
    assert status == :error
    assert error[:code] == 2
  end

  # TODO: Take care of updates via uid 
  test "insert_map/2 returns {:ok, mutation_msg} for correct mutation", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.insert_map(conn, @map_insert_mutation)
    assert status == :ok
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    res = query_msg.result
    people = res["people"]
    alice = List.first(people)
    assert alice["name"] == "Alice"
    betty = List.first(alice["friends"])
    assert betty["name"] == "Betty"
  end

  test "insert_map!/2 returns mutation_message", %{conn: conn} do
    mutation_msg = ExDgraph.insert_map!(conn, @map_insert_mutation)
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    res = query_msg.result
    people = res["people"]
    alice = List.first(people)
    assert alice["name"] == "Alice"
    betty = List.first(alice["friends"])
    assert betty["name"] == "Betty"
  end
end
