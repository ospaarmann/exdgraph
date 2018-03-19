defmodule ExDgraph.Utils.Test do
  use ExUnit.Case
  doctest ExDgraph.Utils

  alias ExDgraph.Utils

  test "as_rendered/1 float" do
    assert Utils.as_rendered(3.14) == "3.14"
  end

  test "as_rendered/1 bool" do
    assert Utils.as_rendered(true) == "true"
  end

  test "as_rendered/1 int" do
    assert Utils.as_rendered(1) == "1"
  end

  test "as_rendered/1 string" do
    assert Utils.as_rendered("beef") == "beef"
  end

  test "as_rendered/1 date" do
    {:ok, written_on} = Date.new(2017, 8, 5)
    assert Utils.as_rendered(written_on) == "2017-08-05T00:00:00.0+00:00"
  end

  test "as_rendered/1 datetime" do
    {:ok, written_at, 0} = DateTime.from_iso8601("2017-08-05T22:32:36.000+00:00")
    assert Utils.as_rendered(written_at) == "2017-08-05T22:32:36.000+00:00"
  end

  test "as_rendered/1 geo (json)" do
    assert Utils.as_rendered([-111.925278, 33.501324]) == "[-111.925278,33.501324]"
  end


  test "as_literal/2 float" do
    assert Utils.as_literal(3.14, :float) == {:ok, "3.14"}
  end

  test "as_literal/2 bool" do
    assert Utils.as_literal(true, :bool) == {:ok, "true"}
  end

  test "as_literal/2 int" do
    assert Utils.as_literal(1, :int) == {:ok, "1"}
  end

  test "as_literal/2 string" do
    assert Utils.as_literal("beef", :string) == {:ok, "\"beef\""}
  end

  test "as_literal/2 date" do
    {:ok, written_on} = Date.new(2017, 8, 5)
    assert Utils.as_literal(written_on, :date) == {:ok, "2017-08-05T00:00:00.0+00:00"}
  end

  test "as_literal/2 datetime" do
    {:ok, written_at, 0} = DateTime.from_iso8601("2017-08-05T22:32:36.000+00:00")
    assert Utils.as_literal(written_at, :datetime) == {:ok, "2017-08-05T22:32:36.000+00:00"}
  end

  test "as_literal/2 geo (json)" do
    assert Utils.as_literal([-111.925278, 33.501324], :geo) == {:ok, "[-111.925278,33.501324]"}
  end

  test "as_literal/2 type error" do
    assert Utils.as_literal("Eef", :int) == {:error, {:invalidly_typed_value, "Eef", :int}}
  end

  test "as_literal/2 uid" do
    assert Utils.as_literal("beef", :uid) == {:ok, "<beef>"}
  end

  test "has_struct?/1 returns false for non-struct-modules" do
    assert Utils.has_struct?(Path) == false
  end

  test "has_struct?/1 returns false for non-struct-atoms" do
    assert Utils.has_struct?(:ok) == false
  end

  test "has_struct?/1 returns true for struct-having-modules" do
    assert Utils.has_struct?(URI) == true
  end

end

# Copyright (c) 2017 Jason Goldberger
# Source https://github.com/elbow-jason/dgraph_ex
