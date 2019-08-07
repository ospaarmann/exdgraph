defmodule ExDgraph.Transform do
  @moduledoc """
  Transform a raw response from Dgraph. For example decode the json part.
  """

  @doc """
  Takes a response from Dgraph, parses the `json` with `Poison` and transforms all string
  keys into atom keys.
  """
  def transform_query(%ExDgraph.Api.Response{json: json, schema: schema, txn: txn}) do
    decoded = Jason.decode!(json)

    transformed =
      case Morphix.atomorphiform(decoded) do
        {:ok, parsed} -> parsed
        _ -> json
      end

    %{
      result: transformed,
      schema: schema,
      txn: txn
    }
  end

  @doc """
  Takes a response from Dgraph and returns a map.
  """
  def transform_mutation(%ExDgraph.Api.Assigned{context: context, uids: uids}) do
    %{
      context: context,
      uids: uids
    }
  end
end
