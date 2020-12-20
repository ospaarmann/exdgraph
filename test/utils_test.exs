defmodule ExDgraph.Utils.Test do
  use ExUnit.Case, async: true

  alias ExDgraph.Utils

  test "atomify_map_keys/1 turns all keys of a nested map into atoms" do
    map = %{
      "name" => "Ole",
      "dogs" => [%{"name" => "Pluto"}],
      "friend" => %{"name" => "Eleasar"},
      already_atom: "value"
    }

    result = Utils.atomify_map_keys(map)

    assert result == %{
             name: "Ole",
             dogs: [%{name: "Pluto"}],
             friend: %{name: "Eleasar"},
             already_atom: "value"
           }
  end
end
