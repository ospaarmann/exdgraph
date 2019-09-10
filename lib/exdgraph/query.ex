defmodule ExDgraph.Query do
  @moduledoc """
  Wrapper for queries sent to DBConnection.
  """

  @type t :: %ExDgraph.Query{
          statement: String.t(),
          parameters: any(),
          txn_context: any()
        }

  defstruct [:statement, :parameters, :txn_context]
end

defimpl DBConnection.Query, for: ExDgraph.Query do
  @moduledoc """
  Implementation of `DBConnection.Query` protocol.
  """

  alias ExDgraph.{Api, Query, QueryResult, Utils}

  @doc """
  This function is called to decode a result after it is returned by a connection callback module.
  """
  def decode(
        _query,
        %ExDgraph.Api.Response{json: json, schema: schema, txn: txn} = _result,
        _opts
      ) do
    data =
      json
      |> Jason.decode!()
      |> Utils.atomify_map_keys()

    %QueryResult{
      data: data,
      schema: schema,
      txn: txn
    }
  end

  @doc """
  This function is called to describe a query after it is prepared using a connection callback module.
  """
  def describe(query, _opts), do: query

  @doc """
  This function is called to encode a query before it is executed using a connection callback module.
  """
  def encode(_query, data, _opts), do: data

  @doc """
  This function is called to parse a query term before it is prepared using a connection callback module.
  """
  def parse(%{statement: nil} = query, _opts), do: %Query{query | statement: ""}

  def parse(%{statement: statement} = query, _opts) do
    %Query{query | statement: IO.iodata_to_binary(statement)}
  end
end
