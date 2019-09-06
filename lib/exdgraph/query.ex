defmodule ExDgraph.Query do
  @moduledoc """
  Provides the functions for the callbacks from the DBConnection behaviour.
  """

  defstruct [:statement, :parameters, :txn_context]
end

defimpl DBConnection.Query, for: ExDgraph.Query do
  @moduledoc """
  Implementation of `DBConnection.Query` protocol.
  """

  alias ExDgraph.{Query, Result, Utils}

  def describe(query, _opts), do: query

  @doc """
  Parse a query.

  This function is called to parse a query term before it is prepared.
  """
  def parse(%{statement: nil} = query, _opts), do: %Query{query | statement: ""}

  def parse(%{statement: statement} = query, _opts) do
    %Query{query | statement: IO.iodata_to_binary(statement)}
  end

  def encode(_query, data, _opts), do: data

  def decode(
        _query,
        %ExDgraph.Api.Response{json: json, schema: schema, txn: txn} = _result,
        _opts
      ) do
    data =
      json
      |> Jason.decode!()
      |> Utils.atomify_map_keys()

    %Result{
      data: data,
      schema: schema,
      txn: txn
    }
  end
end
