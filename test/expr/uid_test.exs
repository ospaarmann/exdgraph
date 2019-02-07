defmodule ExDgraph.Expr.UidTest do
  use ExUnit.Case, async: true

  alias ExDgraph.Expr.Uid
  use ExDgraph.Expr.Uid

  test "uid given a string renders a plain-old uid literal" do
    assert "0x9" |> uid() |> Uid.render() == "<0x9>"
  end

  test "uid given an atom renders a uid expression" do
    assert :some_atom |> uid() |> Uid.render() == "uid(some_atom)"
  end

  test "uid given a list of strings renders a multi-arg uid expr" do
    assert ["0x9", "0x10"] |> uid() |> Uid.render() == "uid(0x9, 0x10)"
  end

  test "uid given a list of atoms renders a multi-arg uid expr" do
    assert [:a, :b, :c] |> uid() |> Uid.render() == "uid(a, b, c)"
  end
end
