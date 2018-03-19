defmodule ExDgraph.QueryStatement do
  @moduledoc false
  defstruct statement: ""
end

defimpl DBConnection.Query, for: ExDgraph.QueryStatement do
  def describe(query, _), do: query

  def parse(query, _), do: query

  def encode(_query, data, _), do: data

  def decode(_, result, _), do: result
end
