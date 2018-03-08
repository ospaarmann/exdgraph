defmodule ExDgraph.Transform do
  @moduledoc """
  Transform a raw response from Dgraph. For example decode the json part.
  This still needs work and improvement.
  """

  def transform(raw) when is_map(raw) do
    Map.put(raw, :result, Poison.decode!(raw.json))
  end
end
