defmodule ExDgraph.Operation do
  @moduledoc """
  Wrapper for operations sent to DBConnection.
  """

  @type t :: %ExDgraph.Operation{
          drop_all: true | false | nil,
          drop_attr: String.t(),
          schema: String.t(),
          txn_context: any()
        }

  defstruct drop_all: false, drop_attr: "", schema: "", txn_context: nil
end

defimpl DBConnection.Query, for: ExDgraph.Operation do
  alias ExDgraph.{Operation, Payload}

  @doc """
  This function is called to decode a result after it is returned by a connection callback module.
  """
  def decode(
        _query,
        %ExDgraph.Api.Payload{Data: data} = _result,
        _opts
      ) do
    %Payload{
      data: data
    }
  end

  @doc """
  This function is called to describe a query after it is prepared using a connection callback module.
  """
  def describe(query, _opts), do: query

  @doc """
  This function is called to encode a query before it is executed using a connection callback module.
  """
  def encode(query, _, _) do
    %{drop_all: drop_all, schema: schema, drop_attr: drop_attr} = query
    %Operation{drop_all: drop_all, schema: schema, drop_attr: drop_attr}
  end

  @doc """
  This function is called to parse a query term before it is prepared using a connection callback module.
  """
  def parse(%{drop_attr: drop_attr, schema: schema, drop_all: _} = query, _opts) do
    %Operation{
      query
      | drop_attr: IO.iodata_to_binary(drop_attr),
        schema: IO.iodata_to_binary(schema)
    }
  end
end
