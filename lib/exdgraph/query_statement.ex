defmodule ExDgraph.QueryStatement do
  @moduledoc false
  defstruct statement: ""
end

defimpl DBConnection.Query, for: ExDgraph.QueryStatement do
  alias ExDgraph.Transform

  def describe(query, _), do: query

  def parse(query, _), do: query

  def encode(_query, data, _), do: data

  def decode(_query, result, _opts), do: Transform.transform_query(result)
end
