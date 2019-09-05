defmodule ExDgraph.Utils do
  @moduledoc "Common utilities"

  alias ExDgraph.Expr.Uid

  def as_rendered(value) do
    case value do
      x when is_list(x) -> x |> Jason.encode!()
      %Date{} = x -> x |> Date.to_iso8601() |> Kernel.<>("T00:00:00.0+00:00")
      %DateTime{} = x -> x |> DateTime.to_iso8601() |> String.replace("Z", "+00:00")
      x -> x |> to_string
    end
  end

  def infer_type(type) do
    case type do
      x when is_boolean(x) -> :bool
      x when is_binary(x) -> :string
      x when is_integer(x) -> :int
      x when is_float(x) -> :float
      x when is_list(x) -> :geo
      %DateTime{} -> :datetime
      %Date{} -> :date
      %Uid{} -> :uid
    end
  end

  def as_literal(value, type) do
    case {type, value} do
      {:int, v} when is_integer(v) -> {:ok, to_string(v)}
      {:float, v} when is_float(v) -> {:ok, as_rendered(v)}
      {:bool, v} when is_boolean(v) -> {:ok, as_rendered(v)}
      {:string, v} when is_binary(v) -> {:ok, v |> strip_quotes |> wrap_quotes}
      {:date, %Date{} = v} -> {:ok, as_rendered(v)}
      {:datetime, %DateTime{} = v} -> {:ok, as_rendered(v)}
      {:geo, v} when is_list(v) -> check_and_render_geo_numbers(v)
      {:uid, v} when is_binary(v) -> {:ok, "<" <> v <> ">"}
      _ -> {:error, {:invalidly_typed_value, value, type}}
    end
  end

  def as_string(value) do
    value
    |> as_rendered
    |> strip_quotes
    |> wrap_quotes
  end

  defp check_and_render_geo_numbers(nums) do
    if nums |> List.flatten() |> Enum.all?(&is_float/1) do
      {:ok, nums |> as_rendered}
    else
      {:error, :invalid_geo_json}
    end
  end

  defp wrap_quotes(value) when is_binary(value) do
    "\"" <> value <> "\""
  end

  defp strip_quotes(value) when is_binary(value) do
    value
    |> String.replace(~r/^"/, "")
    |> String.replace(~r/"&/, "")
  end

  def has_function?(module, func, arity) do
    :erlang.function_exported(module, func, arity)
  end

  def has_struct?(module) when is_atom(module) do
    Code.ensure_loaded?(module)
    has_function?(module, :__struct__, 0)
  end

  def get_value(params, key, default \\ nil) when is_atom(key) do
    str_key = to_string(key)

    cond do
      Map.has_key?(params, key) -> Map.get(params, key)
      Map.has_key?(params, str_key) -> Map.get(params, str_key)
      true -> default
    end
  end

  def atomify_map_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {key, value}, acc when is_atom(key) ->
        Map.put(acc, key, atomify_map_keys(value))

      {key, value}, acc when is_binary(key) ->
        Map.put(acc, String.to_atom(key), atomify_map_keys(value))
    end)
  end

  def atomify_map_keys(list) when is_list(list) do
    for el <- list, do: atomify_map_keys(el)
  end

  def atomify_map_keys(map), do: map
end

# Partly Copyright (c) 2017 Jason Goldberger
# Source https://github.com/elbow-jason/dgraph_ex
