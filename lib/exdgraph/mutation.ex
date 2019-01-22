defmodule ExDgraph.Mutation do
  @moduledoc """
  Provides the functions for the callbacks from the DBConnection behaviour.
  """
  alias ExDgraph.{Exception, MutationStatement, Transform}

  @doc false
  def mutation(conn, statement) do
    case mutation_commit(conn, statement) do
      {:error, f} -> {:error, code: f.code, message: f.message}
      r -> {:ok, r}
    end
  end

  @doc false
  def mutation!(conn, statement) do
    case mutation(conn, statement) do
      {:ok, r} ->
        r

      {:error, code: code, message: message} ->
        raise Exception, code: code, message: message
    end
  end

  @doc false
  def set_map(conn, map) do
    map_with_tmp_uids = insert_tmp_uids(map)
    json = Poison.encode!(map_with_tmp_uids)

    case set_map_commit(conn, json, map_with_tmp_uids) do
      {:error, f} -> {:error, code: f.code, message: f.message}
      r -> {:ok, r}
    end
  end

  @doc false
  def set_map!(conn, map) do
    case set_map(conn, map) do
      {:ok, r} ->
        r

      {:error, code: code, message: message} ->
        raise Exception, code: code, message: message
    end
  end

  @doc false
  def set_struct(conn, struct) do
    uids_and_schema_map = set_tmp_ids_and_schema(struct)
    json = Poison.encode!(uids_and_schema_map)

    case set_struct_commit(conn, json, uids_and_schema_map) do
      {:error, f} -> {:error, code: f.code, message: f.message}
      r -> {:ok, r}
    end
  end

  @doc false
  def set_struct!(conn, struct) do
    case set_struct(conn, struct) do
      {:ok, r} ->
        r

      {:error, code: code, message: message} ->
        raise Exception, code: code, message: message
    end
  end

  defp mutation_commit(conn, statement) do
    exec = fn conn ->
      q = %MutationStatement{statement: statement}

      case DBConnection.execute(conn, q, %{}) do
        {:ok, resp} -> Transform.transform_mutation(resp)
        other -> other
      end
    end

    # Response.transform(DBConnection.run(conn, exec, run_opts()))
    DBConnection.run(conn, exec, run_opts())
  end

  defp set_map_commit(conn, json, map_with_tmp_uids) do
    exec = fn conn ->
      q = %MutationStatement{set_json: json}

      case DBConnection.execute(conn, q, %{}) do
        {:ok, resp} ->
          parsed_response = Transform.transform_mutation(resp)
          # Now exchange the tmp ids for the ones returned from the db
          result_with_uids = replace_tmp_uids(map_with_tmp_uids, parsed_response.uids)
          Map.put(parsed_response, :result, result_with_uids)

        other ->
          other
      end
    end

    # Response.transform(DBConnection.run(conn, exec, run_opts()))
    DBConnection.run(conn, exec, run_opts())
  end

  defp set_struct_commit(conn, json, struct_with_tmp_uids) do
    exec = fn conn ->
      q = %MutationStatement{set_json: json}

      case DBConnection.execute(conn, q, %{}) do
        {:ok, resp} ->
          parsed_response = Transform.transform_mutation(resp)
          # Now exchange the tmp ids for the ones returned from the db
          result_with_uids = replace_tmp_struct_uids(struct_with_tmp_uids, parsed_response.uids)
          Map.put(parsed_response, :result, result_with_uids)

        other ->
          other
      end
    end

    DBConnection.run(conn, exec, run_opts())
  end

  defp insert_tmp_uids(map) when is_list(map), do: Enum.map(map, &insert_tmp_uids/1)

  defp insert_tmp_uids(map) when is_map(map) do
    map
    |> Map.update(:uid, "_:#{UUID.uuid4()}", fn existing_uuid -> existing_uuid end)
    |> Enum.reduce(%{}, fn {key, map_value}, a ->
      Map.merge(a, %{key => insert_tmp_uids(map_value)})
    end)
  end

  defp insert_tmp_uids(value), do: value

  defp set_tmp_ids_and_schema(map) when is_list(map), do: Enum.map(map, &set_tmp_ids_and_schema/1)

  defp set_tmp_ids_and_schema(%x{} = map) do
    schema = x |> get_schema_name()

    map
    |> Map.from_struct()
    |> Map.update(:uid, "_:#{UUID.uuid4()}", fn
      nil -> "_:#{UUID.uuid4()}"
      existing_uuid -> existing_uuid
    end)
    |> Enum.reduce(%{}, fn {key, map_value}, a ->
      set_schema(schema, {key, map_value}, a, ExDgraph.config(:enforce_struct_schema))
    end)
  end

  defp set_tmp_ids_and_schema(map) when is_map(map) do
    map
    |> Map.update(:uid, "_:#{UUID.uuid4()}", fn existing_uuid -> existing_uuid end)
    |> Enum.reduce(%{}, fn {key, map_value}, a ->
      Map.merge(a, %{key => set_tmp_ids_and_schema(map_value)})
    end)
  end

  defp set_tmp_ids_and_schema(value), do: value

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

  defp replace_tmp_struct_uids(map, uids) when is_list(map),
    do: Enum.map(map, &replace_tmp_struct_uids(&1, uids))

  defp replace_tmp_struct_uids(map, uids) when is_map(map) do
    map
    |> Map.update(:uid, map[:uid], fn existing_uuid ->
      case String.slice(existing_uuid, 0, 2) == "_:" do
        true -> uids[String.replace_leading(existing_uuid, "_:", "")]
        false -> existing_uuid
      end
    end)
    |> Enum.reduce(%{}, fn {key, map_value}, a ->
      # delete the schema prefix
      key = key |> to_string() |> String.split(".") |> List.last() |> String.to_existing_atom()
      Map.merge(a, %{key => replace_tmp_struct_uids(map_value, uids)})
    end)
  end

  defp replace_tmp_struct_uids(value, _uids), do: value

  defp get_schema_name(schema) do
    schema |> to_string() |> String.split(".") |> List.last() |> String.downcase()
  end

  defp set_schema(_schema_name, {:uid, map_value}, result, _is_enforced_schema),
    do: Map.merge(result, %{:uid => set_tmp_ids_and_schema(map_value)})

  defp set_schema(schema_name, {key, map_value}, result, is_enforced_schema)
       when is_enforced_schema == true,
       do: Map.merge(result, %{"#{schema_name}.#{key}" => set_tmp_ids_and_schema(map_value)})

  defp set_schema(_schema_name, {key, map_value}, result, _is_enforced_schema),
    do: Map.merge(result, %{key => set_tmp_ids_and_schema(map_value)})

  defp run_opts do
    [pool: ExDgraph.config(:pool)]
  end
end
