defmodule ExDgraph.Utils do
  @moduledoc "Common utilities"

  @doc """
  Turns all keys of a nested map into atoms.

  ## Example

      iex> ExDgraph.Utils.atomify_map_keys(%{"name" => "Ole", "dogs" => [%{"name" => "Pluto"}]})
      %{name: "Ole", dogs: [%{name: "Pluto"}]}

  """
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
