defmodule Graph do
  @moduledoc """
  The graph for gremlin
  """
  require Logger

  # alias Graph

  @doc """
  The graph properties.
  Reserved for a cache (gen_server) and other
  """
  defstruct channel: GRPC.Channel,
            vertex: Vertex,
            edge: Edge,
            vertex_cache: nil

  @doc """
  Creates a new graph
  """
  def new(channel) do
    {:ok, %Graph{channel: channel}}
  end
end
