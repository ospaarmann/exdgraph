defmodule ExDgraph.Query do
  @moduledoc """
  Provides the functions for the callbacks from the DBConnection behaviour.
  """
  alias ExDgraph.{Exception, Error, Query, Transform}

  defstruct [:statement, :parameters, :txn_context]
end

defimpl DBConnection.Query, for: ExDgraph.Query do
  @moduledoc """
  Implementation of `DBConnection.Query` protocol.
  """

  alias ExDgraph.{Result, Utils}

  def describe(query, _), do: query

  @doc """
  Parse a query.

  This function is called to parse a query term before it is prepared.
  """
  def parse(%{statement: nil} = query), do: %{query | statement: ""}

  def parse(%{statement: statement} = query, _) do
    %{query | statement: IO.iodata_to_binary(statement)}
  end

  def encode(_query, data, _), do: data

  def decode(_query, %ExDgraph.Api.Response{json: json, schema: schema, txn: txn} = result, _opts) do
    decoded = Jason.decode!(json)

    transformed =
      case Morphix.atomorphiform(decoded) do
        {:ok, parsed} -> parsed
        _ -> json
      end

    %Result{
      data: transformed,
      schema: schema,
      txn: txn
    }
  end
end
