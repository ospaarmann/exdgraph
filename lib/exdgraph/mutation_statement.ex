defmodule ExDgraph.MutationStatement do
  @moduledoc false
  defstruct statement: "", set_json: ""
end

defimpl DBConnection.Query, for: ExDgraph.MutationStatement do
  def describe(query, _), do: query

  def parse(query, _), do: query

  def encode(_query, data, _), do: data

  def decode(_, result, _), do: result
end
