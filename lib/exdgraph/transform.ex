defmodule ExDgraph.Transform do
  @moduledoc """
  Transform a raw response from Dgraph. For example decode the json part.
  This still needs work and improvement.
  """

  def transform_query(%ExDgraph.Api.Response{json: json, schema: schema, txn: txn}) do
    # TODO: Implement own response module
    decoded = Poison.decode!(json)

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

  def transform_mutation(%ExDgraph.Api.Assigned{context: context, uids: uids}) do
    # TODO: Implement own response module
    %{
      context: context,
      uids: uids
    }
  end
end
