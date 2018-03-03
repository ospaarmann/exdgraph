defmodule Vertex do
  @moduledoc """
  The vertex for gremlin
  """
  require Logger

  @doc """
  The vertex properties.
  Reserved for cache and other
  """
  defstruct graph: Graph,
            uid: String,
            vertex_struct: Struct

  @doc """
  Creates a new graph
  """
  def new(the_graph, the_uid, the_struct) do
    %Vertex{graph: the_graph, uid: the_uid, vertex_struct: the_struct}
  end
end
