defmodule Gremlin do
  @moduledoc """
  Experimental gremlin helper functions
  http://tinkerpop.apache.org/docs/current/reference/#graph-traversal-steps
  """

  require Logger

  @doc """
  Creates a mutaion request with a commit_now and send it to dgraph.
  """
  def mutate_with_commit(graph, nquad) do
    channel = graph.channel
    request = ExDgraph.Api.Mutation.new(set_nquads: nquad, commit_now: true)
    #Logger.info(fn -> "💡 request: #{inspect request}" end)
    {:ok, assigned} = channel |> ExDgraph.Api.Dgraph.Stub.mutate(request)
    assigned
  end

  @doc """
  Creates the nquad and send it as mutaion request with a commit
  """
  def mutate_node(graph, predicate, object) do
    mutate_with_commit(graph, ~s(_:identifier <#{predicate}> "#{object}" .))
  end

  @doc """
  Creates the nquad and send it as mutaion request with a commit
  """
  def mutate_node(graph, subject_uid, predicate, object) do
    mutate_with_commit(graph, ~s(<#{subject_uid}> <#{predicate}> "#{object}" .))
  end

  @doc """
  Creates the nquad and send it as mutaion request with a commit
  """
  def mutate_edge(graph, subject_uid, predicate, object_uid) do
    mutate_with_commit(graph, ~s(<#{subject_uid}> <#{predicate}> <#{object_uid}> .))
  end

  @doc """
  
  """
  def query_vertex(graph, vertex_uid) do
    channel = graph.channel
    query = """
    { vertex(func: uid(#{vertex_uid})) { expand(_all_) } }
    """
    request = ExDgraph.Api.Request.new(query: query)
    {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)
    #Logger.info(fn -> "💡 msg.json: #{inspect msg.json}" end)
    decoded_json = Poison.decode!(msg.json)
    vertices = decoded_json["vertex"]
    vertex_one = List.first(vertices)
    for {key, val} <- vertex_one, into: %{}, do: {String.to_atom(key), val}
  end


  @doc """
  ## AddVertex Step
  The addV()-step is used to add vertices to the graph
  http://tinkerpop.apache.org/docs/current/reference/#addvertex-step
  
  ### Gremlin
      gremlin> g.addV('toon').property('name','Bugs Bunny').property('type','Toon')
      ==>v[13]

  Returns a `Vertex`. The `Graph` with a channel and a struct type are needed.

  ## Examples
  
      {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
      {:ok, graph} = Graph.new(channel)
      graph
      |> addV(Toon)
      |> property("name", "Bugs Bunny")
      |> property("type", "Toon")

  """
  @spec addV(Graph, Struct) :: Vertex
  def addV(graph, struct_type) do
    vertex_struct = struct(struct_type)
    %{__struct__: vertex_type} = vertex_struct
    vertex_type = String.trim_leading(Atom.to_string(vertex_type), "Elixir.")
    assigned = mutate_node(graph, "vertex_type", vertex_type)
    subject_uid = assigned.uids["identifier"]
    Vertex.new(graph, subject_uid, vertex_struct)
  end
  # TODO: Empty addV()

  @doc """
  AddProperty Step
  http://tinkerpop.apache.org/docs/current/reference/#addproperty-step
  """
  @spec property(Vertex, String, String) :: Vertex
  def property(vertex, predicate, object) do
    # TODO: catch unallowed predicates
    # TODO: property value to list ?
    graph = vertex.graph
    assigned = mutate_node(graph, vertex.uid, predicate, object)
    # TODO: update struct in vertex with string as key ?? How ?????
    map_from_struct = Map.from_struct(vertex.vertex_struct)
    new_struct = Map.put(map_from_struct, String.to_atom(predicate), object)
    %{__struct__: vertex_type} = vertex.vertex_struct
    vertex_struct = struct(vertex_type, new_struct)
    %Vertex{vertex | graph: graph, vertex_struct: vertex_struct}
  end
    
  @doc """
  AddEdge Step
  http://tinkerpop.apache.org/docs/current/reference/#addedge-step
  """
  @spec addE(Graph, String) :: Edge
  def addE(graph_or_vertex, predicate) do
    %{__struct__: type} = graph_or_vertex
    case type do
      Graph ->
        Edge.new(graph_or_vertex, predicate)
      Vertex ->
        %Edge{graph: graph_or_vertex.graph, predicate: predicate, from: graph_or_vertex}
    end
  end
 
  @doc """
  AddEdge Step
  http://tinkerpop.apache.org/docs/current/reference/#addedge-step
  """
  @spec from(Edge, Vertex) :: Edge
  def from(edge, from) do
    # TODO: error if no edge set
    %Edge{edge | from: from}
  end

  @doc """
  AddEdge Step
  http://tinkerpop.apache.org/docs/current/reference/#addedge-step
  """
  @spec to(Edge, Vertex) :: Edge
  def to(edge, to) do
    # TODO: error if no edge set or no from or no vertex
    if edge.from != nil do
      assigned = mutate_edge(edge.graph, edge.from.uid, edge.predicate, to.uid)
    else
      assigned = mutate_edge(edge.graph, edge.graph.vertex.uid, edge.predicate, to.uid)
    end
    %Edge{edge | to: to}
  end

  @doc """
  V Step
  
  The vertex iterator for the graph. Utilize this to iterate through all the vertices in the graph. 
  Use with care on large graphs unless used in combination with a key index lookup.

  ### Get all the vertices in the Graph
  gremlin> g.V()

  ### Get a vertex with the unique identifier of "1".
  gremlin> g.V(1)

  ### Get the value of the name property on vertex with the unique identifier of "1".
  gremlin> g.V(1).values('name')

  ### 
  """
  @spec v(Graph) :: List
  def v(graph) do
    # TODO: implement
    []
  end

  @doc """
  Get a vertex with the unique identifier.

  Returns a `Vertex`. The `Graph` with a channel and a `uid` are needed.

  ## Examples
  
      {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
      {:ok, graph} = Graph.new(channel)
      graph
  
  """
  @spec v(Graph, String) :: Vertex
  def v(graph, uid) do
    vertex = query_vertex(graph, uid)
    #Logger.info(fn -> "💡 vertex: #{inspect vertex}" end)
    struct_type = String.to_existing_atom("Elixir." <> vertex.vertex_type)
    struct = struct(struct_type, vertex)
    #Logger.info(fn -> "💡 struct: #{inspect struct}" end)
    %Vertex{graph: graph, uid: uid, vertex_struct: struct}
  end
  # TODO: v(graph, property, object) # gremlin> g.V("name", "marko").name
  
  @spec values(Vertex, String) :: List
  def values(vertex, predicate) do
    graph = vertex.graph
  end
end
