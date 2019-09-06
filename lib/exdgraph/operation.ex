defmodule ExDgraph.Operation do
  @moduledoc """
  Provides the functions for the callbacks from the DBConnection behaviour.
  """
  alias ExDgraph.Error

  defstruct drop_all: false, drop_attr: "", schema: "", txn_context: nil
end

defimpl DBConnection.Query, for: ExDgraph.Operation do
  alias ExDgraph.{Operation, Payload}

  def describe(query, _opts), do: query

  def parse(%{drop_attr: drop_attr, schema: schema, drop_all: _} = query, _opts) do
    %Operation{
      query
      | drop_attr: IO.iodata_to_binary(drop_attr),
        schema: IO.iodata_to_binary(schema)
    }
  end

  def encode(query, _, _) do
    %{drop_all: drop_all, schema: schema, drop_attr: drop_attr} = query
    %Operation{drop_all: drop_all, schema: schema, drop_attr: drop_attr}
  end

  def decode(
        _query,
        %ExDgraph.Api.Payload{Data: data} = _result,
        _opts
      ) do
    %Payload{
      data: data
    }
  end
end
