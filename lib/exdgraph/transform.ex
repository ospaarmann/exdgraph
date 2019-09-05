defmodule ExDgraph.Transform do
  @moduledoc """
  Transform a raw response from Dgraph. For example decode the json part.
  """

  @doc """
  Takes a response from Dgraph and returns a map.
  """
  def transform_mutation(%ExDgraph.Api.Assigned{context: context, uids: uids}) do
    %{
      context: context,
      uids: uids
    }
  end
end
