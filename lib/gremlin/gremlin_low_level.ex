defmodule ExDgraph.Gremlin.LowLevel do
  @moduledoc """
  Low level functions
  """
  require Logger
  alias ExDgraph.Gremlin.LowLevel

  @doc """
  Creates a mutaion request with a commit_now and send it to dgraph.
  """
  def mutate_with_commit(graph, nquad) do
    channel = graph.channel
    request = ExDgraph.Api.Mutation.new(set_nquads: nquad, commit_now: true)
    # Logger.info(fn -> "💡 request: #{inspect request}" end)
    channel |> ExDgraph.Api.Dgraph.Stub.mutate(request)
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
    # Logger.info(fn -> "💡 msg.json: #{inspect msg.json}" end)
    decoded_json = Poison.decode!(msg.json)
    vertices = decoded_json["vertex"]
    [vertex_one] = vertices
    vertex = for {key, val} <- vertex_one, into: %{}, do: {String.to_atom(key), val}
    struct_type = String.to_existing_atom("Elixir." <> vertex.vertex_type)
    struct(struct_type, vertex)
  end

  @doc """

  """
  def query_vertex(graph, predicate, object, display) do
    channel = graph.channel
    if display != "expand(_all_)" do
      display = "vertex_type " <> display
    end
    query = """
    { vertices(func: anyofterms(#{predicate}, \"#{object}\")) { #{display} } }
    """

    request = ExDgraph.Api.Request.new(query: query)
    {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)
    decoded_json = Poison.decode!(msg.json)
    vertices = decoded_json["vertices"]
    Logger.info(fn -> "💡 vertices: #{inspect vertices}" end)
    map =
      Enum.map(vertices, fn vertex_map ->
        vertex = for {key, val} <- vertex_map, into: %{}, do: {String.to_atom(key), val}
        struct_type = String.to_existing_atom("Elixir." <> vertex.vertex_type)
        struct(struct_type, vertex)
      end)

    map
  end
  def query_vertex(graph, predicate, object) do
    query_vertex(graph, predicate, object, "expand(_all_)")
  end
end
