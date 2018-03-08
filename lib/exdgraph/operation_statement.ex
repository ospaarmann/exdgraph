defmodule ExDgraph.OperationStatement do
  defstruct drop_all: false, drop_attr: "", schema: ""
end

defimpl DBConnection.Query, for: ExDgraph.OperationStatement do
  def describe(operation, _), do: operation

  def parse(operation, _), do: operation

  def encode(_operation, data, _), do: data

  def decode(_, result, _), do: result
end
