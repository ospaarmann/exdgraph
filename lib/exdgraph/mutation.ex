defmodule ExDgraph.Mutation do
  @moduledoc """
  Wrapper for mutations sent to DBConnection.
  """

  alias ExDgraph.{Exception, Transform}

  @type t :: %ExDgraph.Mutation{
          statement: String.t() | map() | struct(),
          set_json: String.t(),
          txn_context: any(),
          original_statement: any()
        }

  defstruct statement: nil, set_json: nil, txn_context: nil, original_statement: nil
end

defimpl DBConnection.Query, for: ExDgraph.Mutation do
  @moduledoc """
  Implementation of `DBConnection.Query` protocol.
  """

  alias ExDgraph.{Api, Mutation, MutationResult, Transform, Utils}

  @doc """
  This function is called to decode a result after it is returned by a connection callback module.
  """
  def decode(
        %Mutation{
          set_json: set_json,
          statement: statement,
          original_statement: original_statement
        } = query,
        %Api.Assigned{context: context, latency: latency, uids: uids} = _result,
        _opts
      )
      when is_binary(set_json) and is_nil(statement) do
    data =
      set_json
      |> Jason.decode!()
      |> Utils.atomify_map_keys()
      |> replace_tmp_uids(uids)
      |> merge_result_with_statement(original_statement)

    %MutationResult{
      data: data,
      txn_context: context,
      latency: latency,
      uids: uids
    }
  end

  def decode(
        %Mutation{
          set_json: set_json,
          statement: statement
        } = query,
        %Api.Assigned{context: context, latency: latency, uids: uids} = _result,
        _opts
      )
      when is_nil(set_json) and is_binary(statement) do
    %MutationResult{
      txn_context: context,
      latency: latency,
      uids: uids
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
  def parse(%{statement: %{__struct__: struct_name} = statement} = query, _opts) do
    json =
      statement
      |> Map.from_struct()
      |> insert_tmp_uids()
      |> Jason.encode!()

    %Mutation{query | statement: nil, set_json: json, original_statement: statement}
  end

  def parse(%{statement: statement} = query, _opts) when is_map(statement) do
    json =
      statement
      |> insert_tmp_uids()
      |> Jason.encode!()

    %Mutation{query | statement: nil, set_json: json, original_statement: statement}
  end

  def parse(%{statement: statement} = query, _opts) when is_binary(statement) do
    %Mutation{query | statement: IO.iodata_to_binary(statement), original_statement: statement}
  end

  defp insert_tmp_uids(map, acc \\ 0)

  defp insert_tmp_uids(map, acc) when is_list(map),
    do: Enum.map(map, &insert_tmp_uids(&1, acc).())

  defp insert_tmp_uids(map, acc) when is_map(map) do
    map
    |> Map.update(:uid, "_:#{acc}", fn existing_uuid -> existing_uuid end)
    |> Enum.reduce(%{}, fn {key, map_value}, a ->
      new_acc = acc + 1
      Map.merge(a, %{key => insert_tmp_uids(map_value, new_acc)})
    end)
  end

  defp insert_tmp_uids(value, acc), do: value

  defp replace_tmp_uids(map, uids) when is_list(map),
    do: Enum.map(map, &replace_tmp_uids(&1, uids))

  defp replace_tmp_uids(map, uids) when is_map(map) do
    map
    |> Map.update(:uid, map[:uid], fn existing_uuid ->
      case String.slice(existing_uuid, 0, 2) == "_:" do
        true -> uids[String.replace_leading(existing_uuid, "_:", "")]
        false -> existing_uuid
      end
    end)
    |> Enum.reduce(%{}, fn {key, map_value}, a ->
      Map.merge(a, %{key => replace_tmp_uids(map_value, uids)})
    end)
  end

  defp replace_tmp_uids(value, _uids), do: value

  defp merge_result_with_statement(result, %{__struct__: struct_name} = _original_statement) do
    struct(struct_name, result)
  end

  defp merge_result_with_statement(result, _original_statement), do: result
end
