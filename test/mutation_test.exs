defmodule MutationTest.Person do
  defstruct [:uid, :name, :identifier, :dogs]
end

defmodule MutationTest.Dog do
  defstruct [:uid, :name]
end

defmodule MutationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  import ExDgraph.TestHelper

  @struct_insert_mutation %MutationTest.Person{
    name: "Alice",
    identifier: "alice_json",
    dogs: [
      %MutationTest.Dog{
        name: "Betty"
      }
    ]
  }

  @struct_insert_check_query """
    {
        people(func: allofterms(person.identifier, "alice_json"))
        {
          uid
          name : person.name
          dogs : person.dogs
          {
            name : dog.name
            uid
          }
        }
    }
  """

  @map_insert_mutation %{
    name: "Alice",
    identifier: "alice_json",
    friends: [
      %{
        name: "Betty"
      }
    ]
  }

  @map_insert_check_query """
    {
        people(func: allofterms(identifier, "alice_json"))
        {
          uid
          name
          friends
          {
            name,
            uid
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
  test "set_map/2 returns {:ok, mutation_msg} for correct mutation", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.set_map(conn, @map_insert_mutation)
    assert status == :ok
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    res = query_msg.result
    people = res[:people]
    alice = List.first(people)
    assert alice[:name] == "Alice"
    betty = List.first(alice[:friends])
    assert betty[:name] == "Betty"
  end

  test "set_map!/2 returns mutation_message", %{conn: conn} do
    mutation_msg = ExDgraph.set_map!(conn, @map_insert_mutation)
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    res = query_msg.result
    people = res[:people]
    alice = List.first(people)
    assert alice[:name] == "Alice"
    betty = List.first(alice[:friends])
    assert betty[:name] == "Betty"
  end

  test "set_map/2 returns result with uids", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.set_map(conn, @map_insert_mutation)
    assert status == :ok
    assert is_map(mutation_msg.result)
    mutation_alice = mutation_msg.result
    mutation_betty = List.first(mutation_alice[:friends])
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    query_people = query_msg.result[:people]
    query_alice = List.first(query_people)
    query_betty = List.first(query_alice[:friends])
    assert mutation_alice[:uid] == query_alice[:uid]
    assert mutation_betty[:uid] == query_betty[:uid]
  end

  test "set_map!/2 returns result with uids", %{conn: conn} do
    mutation_msg = ExDgraph.set_map!(conn, @map_insert_mutation)
    assert is_map(mutation_msg.result)
    mutation_alice = mutation_msg.result
    mutation_betty = List.first(mutation_alice[:friends])
    query_msg = ExDgraph.Query.query!(conn, @map_insert_check_query)
    query_people = query_msg.result[:people]
    query_alice = List.first(query_people)
    query_betty = List.first(query_alice[:friends])
    assert mutation_alice[:uid] == query_alice[:uid]
    assert mutation_betty[:uid] == query_betty[:uid]
  end

  # TODO: Take care of updates via uid
  test "set_map/2 struct returns {:ok, mutation_msg} for correct mutation", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.set_struct(conn, @struct_insert_mutation)
    assert status == :ok
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @struct_insert_check_query)
    res = query_msg.result
    people = res[:people]
    alice = List.first(people)
    assert alice[:name] == "Alice"
    betty = List.first(alice[:dogs])
    assert betty[:name] == "Betty"
  end

  test "set_map!/2 struct returns mutation_message", %{conn: conn} do
    mutation_msg = ExDgraph.set_struct!(conn, @struct_insert_mutation)
    assert mutation_msg.context.aborted == false
    query_msg = ExDgraph.Query.query!(conn, @struct_insert_check_query)
    res = query_msg.result
    people = res[:people]
    alice = List.first(people)
    assert alice[:name] == "Alice"
    betty = List.first(alice[:dogs])
    assert betty[:name] == "Betty"
  end

  test "set_map/2 struct returns result with uids", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.set_struct(conn, @struct_insert_mutation)
    assert status == :ok
    assert is_map(mutation_msg.result)
    mutation_alice = mutation_msg.result
    mutation_betty = List.first(mutation_alice[:dogs])
    query_msg = ExDgraph.Query.query!(conn, @struct_insert_check_query)
    query_people = query_msg.result[:people]
    query_alice = List.first(query_people)
    query_betty = List.first(query_alice[:dogs])
    assert mutation_alice[:uid] == query_alice[:uid]
    assert mutation_betty[:uid] == query_betty[:uid]
  end

  test "set_map!/2 struct returns result with uids", %{conn: conn} do
    mutation_msg = ExDgraph.set_struct!(conn, @struct_insert_mutation)
    assert is_map(mutation_msg.result)
    mutation_alice = mutation_msg.result
    mutation_betty = List.first(mutation_alice[:dogs])
    query_msg = ExDgraph.Query.query!(conn, @struct_insert_check_query)
    query_people = query_msg.result[:people]
    query_alice = List.first(query_people)
    query_betty = List.first(query_alice[:dogs])
    assert mutation_alice[:uid] == query_alice[:uid]
    assert mutation_betty[:uid] == query_betty[:uid]
  end

  test "set_map/2 updates a node if a uid is present and returns the uid again", %{conn: conn} do
    user = %{name: "bob", occupation: "dev"}
    {:ok, res} = ExDgraph.set_map(conn, user)

    other_mutation = %{
      uid: res.result.uid,
      friends: [%{name: "Paul", occupation: "diver"}, %{name: "Lisa", gender: "female"}]
    }

    {:ok, res2} = ExDgraph.set_map(conn, other_mutation)
    assert res.result.uid == res2.result.uid
  end
end
