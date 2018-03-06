defmodule ExDgraph.Gremlin.GremlinAddTest do
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
  require Logger
  use ExUnit.Case
  import ExDgraph.Gremlin
  alias ExDgraph.Gremlin.Toon
  alias ExDgraph.Gremlin.Person
  alias ExDgraph.Gremlin.Graph

  doctest ExDgraph.Gremlin
  @testing_schema "id: string @index(exact).
    name: string @index(exact, term) @count .
    knows: uid .
    type: string .
    age: int @index(int) .
    friend: uid @count .
    dob: dateTime ."

  # setup_all do
  #   #Logger.info(fn -> "💡 GRPC-Server: #{Application.get_env(:exdgraph, :dgraphServerGRPC)}" end)
  #   {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
  #   operation = ExDgraph.Api.Operation.new(drop_all: true)
  #   {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
  #   operation = ExDgraph.Api.Operation.new(schema: @testing_schema)
  #   {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
  #   :ok
  # end

  setup do
    #   Logger.info(fn -> "💡 Setup " end)
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

    [toon_one] = ExDgraph.Gremlin.LowLevel.query_vertex(graph, "name", "Bugs Bunny")
    assert "Bugs Bunny" == toon_one.name
    assert "Toon" == toon_one.type
  end

  test "Gremlin AddVertex Step ; AddProperty Step ! version" do
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    {:ok, graph} = Graph.new(channel)

    graph
    |> addV!(Toon)
    |> property!("name", "Bugs Bunny")
    |> property!("type", "Toon")

    [toon_one] = ExDgraph.Gremlin.LowLevel.query_vertex(graph, "name", "Bugs Bunny")
    assert "Bugs Bunny" == toon_one.name
    assert "Toon" == toon_one.type
  end

  test "Gremlin AddEdge Step" do
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    {:ok, graph} = Graph.new(channel)

    {:ok, marko} =
      graph
      |> addV(Person)
      |> property("name", "Makro")

    {:ok, peter} =
      graph
      |> addV(Person)
      |> property("name", "Peter")

    # gremlin> g.addE('knows').from(marko).to(peter)
    graph
    |> addE("knows")
    |> from(marko)
    |> to(peter)

    # gremlin> g.V(john).addE('knows').to(peter)
    {:ok, edge} =
      graph
      |> addV(Person)
      |> property("name", "John")
      |> addE("knows")
      |> to(peter)

    assert "knows" == edge.predicate

    [person_one] = ExDgraph.Gremlin.LowLevel.query_vertex(graph, "name", "John", "uid name knows { name }")
    #Logger.info(fn -> "💡 person_one: #{inspect person_one}" end)
    assert "John" == person_one.name
    assert "Peter" == List.first(person_one.knows)["name"]
  end

  test "Gremlin Vertex Step" do
    {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
    {:ok, graph} = Graph.new(channel)

    {:ok, edwin} =
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
