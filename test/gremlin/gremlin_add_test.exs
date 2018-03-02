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

  setup_all do
    Logger.info fn -> "💡 GRPC-Server: #{Application.get_env(:exdgraph, :dgraphServerGRPC)}" end
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    operation = ExDgraph.Api.Operation.new(drop_all: true)
    {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
    operation = ExDgraph.Api.Operation.new(schema: @testing_schema)
    {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
    :ok
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
