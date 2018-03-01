defmodule Gremlin do
    @moduledoc """
    Experimental gremlin helper functions
    http://tinkerpop.apache.org/docs/current/reference/#graph-traversal-steps
    """
  
    require Logger
  
    def mutate_with_commit(nquad) do
      {:ok, channel} = GRPC.Stub.connect("localhost:9082")
      request = ExDgraph.Api.Mutation.new(set_nquads: nquad, commit_now: true)
      {:ok, assigned} = channel |> ExDgraph.Api.Dgraph.Stub.mutate(request)
      assigned
    end

    def mutate_node(predicate, object) do
      mutate_with_commit(~s(_:identifier <#{predicate}> "#{object}" .))
    end

    def mutate_node(subject_uid, predicate, object) do
      mutate_with_commit(~s(<#{subject_uid}> <#{predicate}> "#{object}" .))
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
      assigned = mutate_node("vertex_type", vertex_type)
      subject_uid = assigned.uids["identifier"]
      Vertex.new(subject_uid, vertex_struct)
    end
  
    @doc """
    AddProperty Step
    http://tinkerpop.apache.org/docs/current/reference/#addproperty-step
    """
    @spec property(Vertex, String, String) :: Vertex
    def property(vertex, predicate, object) do
      #Logger.info fn -> "💡 vertex #{inspect vertex}" end
      assigned = mutate_node(vertex.uid, predicate, object)
      # TODO: update struct in vertex
      vertex
    end
  end
  