defmodule GremlinAddTest do
  @moduledoc """

  # Gremlin tests

  ## AddVertex Step & AddProperty Step

      graph
          |> addV(Toon)
          |> property("name", "Bugs Bunny")
          |> property("type", "Toon")

  ## AddEdge Step

      graph
          |> addE("knows")
          |> from(marko)
          |> to(peter)




  """
  use ExUnit.Case
  import Gremlin
  require Logger

  @testing_schema "id: string @index(exact).
    name: string @index(exact, term) @count .
    knows: uid .
    type: string .
    age: int @index(int) .
    friend: uid @count .
    dob: dateTime ."

  setup_all do
    #Logger.info(fn -> "💡 GRPC-Server: #{Application.get_env(:exdgraph, :dgraphServerGRPC)}" end)
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    operation = ExDgraph.Api.Operation.new(drop_all: true)
    {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
    operation = ExDgraph.Api.Operation.new(schema: @testing_schema)
    {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
    :ok
  end

  # setup do
  #   Logger.info(fn -> "💡 Setup " end)
  # end
  
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

  test "Gremlin AddEdge Step" do
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    {:ok, graph} = Graph.new(channel)

    marko =
      graph
      |> addV(Person)
      |> property("name", "Makro")

    peter =
      graph
      |> addV(Person)
      |> property("name", "Peter")

    # gremlin> g.addE('knows').from(marko).to(peter)
    graph
    |> addE("knows")
    |> from(marko)
    |> to(peter)

    # gremlin> g.V(john).addE('knows').to(peter)
    edge =
      graph
      |> addV(Person)
      |> property("name", "John")
      |> addE("knows")
      |> to(peter)
      assert "knows" == edge.predicate
    # TODO: Helper func 
    # Connect to Server
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))

    query = """
      {
        person(func: anyofterms(name, "John"))
        {
          uid
          name
          knows { name }
        }
      }
    """

    request = ExDgraph.Api.Request.new(query: query)
    {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)
    json = Poison.decode!(msg.json)
    persons = json["person"]
    #Logger.info(fn -> "💡 json: #{inspect json}" end)
    person_one = List.first(persons)
    assert "John" == person_one["name"]
    assert "Peter" == List.first(person_one["knows"])["name"]
  end

  test "Gremlin Vertex Step" do
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    {:ok, graph} = Graph.new(channel)

    edwin =
      graph
      |> addV(Person)
      |> property("name", "Edwin")
      
    # Get all the vertices in the Graph (NOT IMPLEMENTED)
    vertices =
      graph
      |> v()

    assert [] == vertices
    
    # Get a vertex with the unique identifier of "1".
    vertex =
    graph
    |> v(edwin.uid)

    assert edwin.uid == vertex.uid
    %{__struct__: match_struct} = vertex.vertex_struct
    assert Person == match_struct
    assert "Edwin" == vertex.vertex_struct.name

    # Get the value of the name property on vertex with the unique identifier of uid.
    vertex =
    graph
    |> v(edwin.uid)
    |> values("name")
  end
end
