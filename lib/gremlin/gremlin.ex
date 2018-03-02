defmodule Gremlin do
  @moduledoc """
  Experimental gremlin helper functions
  http://tinkerpop.apache.org/docs/current/reference/#graph-traversal-steps
  """

  require Logger

  def mutate_with_commit(graph, nquad) do
    channel = graph.channel
    request = ExDgraph.Api.Mutation.new(set_nquads: nquad, commit_now: true)
    {:ok, assigned} = channel |> ExDgraph.Api.Dgraph.Stub.mutate(request)
    assigned
  end

  def mutate_node(graph, predicate, object) do
    mutate_with_commit(graph, ~s(_:identifier <#{predicate}> "#{object}" .))
  end

  def mutate_node(graph, subject_uid, predicate, object) do
    mutate_with_commit(graph, ~s(<#{subject_uid}> <#{predicate}> "#{object}" .))
  end

  @doc """
  AddVertex Step
  http://tinkerpop.apache.org/docs/current/reference/#addvertex-step
  """
  @spec addV(Graph, Struct) :: Struct
  def addV(graph, struct) do
    vertex_struct = struct(struct)
    %{__struct__: vertex_type} = vertex_struct
    vertex_type = String.trim_leading(Atom.to_string(vertex_type), "Elixir.")
    assigned = mutate_node(graph, "vertex_type", vertex_type)
    subject_uid = assigned.uids["identifier"]
    %Graph{graph | vertex: Vertex.new(subject_uid, vertex_struct)}
  end

  @doc """
  AddProperty Step
  http://tinkerpop.apache.org/docs/current/reference/#addproperty-step
  """
  @spec property(Vertex, String, String) :: Vertex
  def property(graph, predicate, object) do
    # TODO: catch unallowed predicates
    # TODO: property value to list ?
    # Logger.info fn -> "💡 vertex #{inspect vertex}" end
    vertex = graph.vertex
    #   Logger.info fn -> "💡 vertex #{inspect vertex}" end
    assigned = mutate_node(graph, vertex.uid, predicate, object)
    # TODO: update struct in vertex with string as key ?? How ?????
    # Logger.info fn -> "💡 String.to_atom(predicate) #{inspect String.to_atom(predicate)}" end  
    map_from_struct = Map.from_struct(vertex.vertex_struct)
    new_struct = Map.put(map_from_struct, String.to_atom(predicate), object)
    %{__struct__: vertex_type} = vertex.vertex_struct
    vertex_struct = struct(vertex_type, new_struct)
    vertex = %Vertex{vertex | vertex_struct: vertex_struct}
    %Graph{graph | vertex: vertex}
  end
end
