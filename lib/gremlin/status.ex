
defmodule ExDgraph.Gremlin.Status do
  @type t :: non_neg_integer
  @doc """
  Not an error; returned on success.
  """
  def ok, do: 0
end
