defmodule MutationTest.Person do
  defstruct [:uid, :name, :identifier, :dogs, :some_map]
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
    ],
    some_map: %{
      some: "value",
      map_owner: %MutationTest.Person{
        name: "Bob"
      }
    }
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
          some_map : person.some_map
          {
            uid
            some
            map_owner
            {
              uid
              name : person.name
            }
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
    {:ok, conn} = ExDgraph.start_link()
    ExDgraph.alter(conn, %{drop_all: true})
    import_starwars_sample(conn)

    [conn: conn]
  end

  describe "mutate/3" do
    test "it returns {:ok, %Mutation{}, %MutationResult{}} for correct mutation", %{
      conn: conn
    } do
      {status, _mutation, result} = ExDgraph.mutate(conn, starwars_creation_mutation())
      assert status == :ok
      assert result.txn_context.aborted == false
    end

    test "it returns {:error, error} for incorrect mutation", %{conn: conn} do
      {status, error} = ExDgraph.mutate(conn, "wrong")
      assert status == :error
      assert error.code == 2
    end

    test "it writes the data to Dgraph", %{
      conn: conn
    } do
      {status, _mutation, result} = ExDgraph.mutate(conn, @map_insert_mutation)
      assert status == :ok
      assert result.txn_context.aborted == false
      query_msg = ExDgraph.query!(conn, @map_insert_check_query)
      res = query_msg.data
      people = res[:people]
      alice = List.first(people)
      assert alice[:name] == "Alice"
      betty = List.first(alice[:friends])
      assert betty[:name] == "Betty"
    end

    test "it returns result with uids", %{conn: conn} do
      {status, _mutation, result} = ExDgraph.mutate(conn, @map_insert_mutation)
      assert status == :ok
      assert is_map(result.data)
      mutation_alice = result.data
      mutation_betty = List.first(mutation_alice[:friends])
      query_msg = ExDgraph.query!(conn, @map_insert_check_query)
      query_people = query_msg.data[:people]
      query_alice = List.first(query_people)
      query_betty = List.first(query_alice[:friends])
      assert mutation_alice[:uid] == query_alice[:uid]
      assert mutation_betty[:uid] == query_betty[:uid]
    end

    test "it updates a node if a uid is present and returns the uid again", %{conn: conn} do
      user = %{name: "bob", occupation: "dev"}
      {:ok, _mutation, result} = ExDgraph.mutate(conn, user)

      other_mutation = %{
        uid: result.data.uid,
        friends: [%{name: "Paul", occupation: "diver"}, %{name: "Lisa", gender: "female"}]
      }

      {:ok, _mutation, result2} = ExDgraph.mutate(conn, other_mutation)
      assert result.data.uid == result2.data.uid
    end
  end

  describe "mutate!/3" do
    test "it returns %MutationResult{} for correct mutation", %{
      conn: conn
    } do
      result = ExDgraph.mutate!(conn, starwars_creation_mutation())
      assert result.txn_context.aborted == false
    end

    test "it raises ExDgraph.Error for incorrect mutation", %{conn: conn} do
      assert_raise(ExDgraph.Error, fn ->
        ExDgraph.mutate!(conn, "wrong")
      end)
    end

    test "it writes the data to Dgraph", %{
      conn: conn
    } do
      result = ExDgraph.mutate!(conn, @map_insert_mutation)
      assert result.txn_context.aborted == false
      query_msg = ExDgraph.query!(conn, @map_insert_check_query)
      res = query_msg.data
      people = res[:people]
      alice = List.first(people)
      assert alice[:name] == "Alice"
      betty = List.first(alice[:friends])
      assert betty[:name] == "Betty"
    end

    test "it returns result with uids", %{conn: conn} do
      result = ExDgraph.mutate!(conn, @map_insert_mutation)
      assert is_map(result.data)
      mutation_alice = result.data
      mutation_betty = List.first(mutation_alice[:friends])
      query_msg = ExDgraph.query!(conn, @map_insert_check_query)
      query_people = query_msg.data[:people]
      query_alice = List.first(query_people)
      query_betty = List.first(query_alice[:friends])
      assert mutation_alice[:uid] == query_alice[:uid]
      assert mutation_betty[:uid] == query_betty[:uid]
    end

    test "it updates a node if a uid is present and returns the uid again", %{conn: conn} do
      user = %{name: "bob", occupation: "dev"}
      result = ExDgraph.mutate!(conn, user)

      other_mutation = %{
        uid: result.data.uid,
        friends: [%{name: "Paul", occupation: "diver"}, %{name: "Lisa", gender: "female"}]
      }

      result2 = ExDgraph.mutate!(conn, other_mutation)
      assert result.data.uid == result2.data.uid
    end
  end
end
