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
    vertex_one = List.first(vertices)
    for {key, val} <- vertex_one, into: %{}, do: {String.to_atom(key), val}
  end
end
