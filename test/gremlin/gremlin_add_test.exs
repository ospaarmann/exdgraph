defmodule GremlinAddTest do
  @moduledoc """
  """
  use ExUnit.Case
  import Gremlin
  require Logger

  @testing_schema "id: string @index(exact).
    name: string @index(exact, term) @count .
    age: int @index(int) .
    friend: uid @count .
    dob: dateTime ."

  @doc """
  Defines a callback to be run before all tests in a case.
  """
  setup_all do
    IO.puts("🛡 💡 dgraph setup all: #{Application.get_env(:exdgraph, :dgraphServerGRPC)}")
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    IO.puts("🛡 💡 Drop dgraph DB")
    operation = ExDgraph.Api.Operation.new(drop_all: true)
    {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
    IO.puts("🛡 💡 Drop dgraph DB")
    # Schema
    IO.puts("🛡 💡 Write schema dgraph DB")
    operation = ExDgraph.Api.Operation.new(schema: @testing_schema)
    {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
    :ok
  end

  test "Query" do
    # Port: 9080 or 9082
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    # Define query (for now just a string)
    m = """
     _:class <student> _:x .
           _:class <student> _:y .
           _:class <name> "awesome class" .
           _:x <name> "Alice" .
           _:x <planet> "Mars" .
           _:x <friend> _:y .
           _:y <name> "Bob" .
    """

    # Build request
    request = ExDgraph.Api.Mutation.new(set_nquads: m, commit_now: true)
    # Send request to server
    {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.mutate(request)

    query = """
      {
        toons(func: anyofterms(name, "Alice"))
        {
          uid
          name
          planet
        }
      }
    """

    request = ExDgraph.Api.Request.new(query: query)
    {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)
    json = Poison.decode!(msg.json)
    toons = json["toons"]
    toon_one = List.first(toons)
    assert "Alice" == toon_one["name"]
    assert "Mars" == toon_one["planet"]
  end

  test "Gremlin AddVertex Step ; AddProperty Step" do
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    {:ok, graph} = Graph.new(channel)

    graph
    |> addV(Toon)
    |> property("name", "Bugs Bunny")
    |> property("type", "Toon")

    # TODO: Helper func
    # Connect to Server
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))

    query = """
      {
        toons(func: anyofterms(name, "Bugs Bunny"))
        {
          uid
          name
          type
        }
      }
    """

    request = ExDgraph.Api.Request.new(query: query)
    {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)
    json = Poison.decode!(msg.json)
    toons = json["toons"]
    toon_one = List.first(toons)
    assert "Bugs Bunny" == toon_one["name"]
    assert "Toon" == toon_one["type"]
  end
end
