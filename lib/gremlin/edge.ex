defmodule Edge do
  @moduledoc """
  And edge for gremlin
  """
  require Logger

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
