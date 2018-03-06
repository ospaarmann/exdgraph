defmodule ExDgraph.Gremlin.Edge do
  @moduledoc """
  And edge for gremlin
  """
  require Logger
  alias ExDgraph.Gremlin.Edge
  alias ExDgraph.Gremlin.Graph
  alias ExDgraph.Gremlin.Vertex
  @doc """
  The edge properties.
  Reserved for cache and other
  """
  defstruct graph: Graph,
            predicate: String,
            from: Vertex,
            to: Vertex

  @doc """
  Creates a new graph
  """
  def new(the_graph, predicate) do
    %Edge{graph: the_graph, predicate: predicate}
  end
end
