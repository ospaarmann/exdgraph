defmodule ExDgraph.Transform do
  @moduledoc """
  Transform a raw response from Dgraph. For example decode the json part.
  This still needs work and improvement.
  """

  def transform_query(%ExDgraph.Api.Response{json: json, schema: schema, txn: txn}) do
    # TODO: Implement own response module
    %{
      result: Poison.decode!(json),
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
