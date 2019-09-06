defmodule ExDgraph.OperationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  import ExDgraph.TestHelper

  alias ExDgraph.{Error, Payload}

  setup do
    {:ok, conn} = ExDgraph.start_link()
    ExDgraph.alter(conn, %{drop_all: true})
    import_starwars_sample(conn)

    [conn: conn]
  end

  test "alter(%{drop_all: true}) is successful", %{conn: conn} do
    {status, _operation, payload} = ExDgraph.alter(conn, %{drop_all: true})
    assert status == :ok
    assert payload == %Payload{data: ""}
  end

  test "alter/3 returns the operation", %{conn: conn} do
    {:ok, operation, _payload} = ExDgraph.alter(conn, %{drop_all: true})
    assert %{drop_all: true} = operation
  end

  test "alter/3 returns {:error, error} for incorrect operation", %{conn: conn} do
    {status, error} = ExDgraph.alter(conn, %{})
    assert status == :error

    assert %Error{action: :alter, code: 2, reason: "Operation must have at least one field set"} =
             error
  end

  test "alter!(%{drop_all: true}) is successful", %{conn: conn} do
    payload = ExDgraph.alter!(conn, %{drop_all: true})
    assert payload == %Payload{data: ""}
  end

  test "alter!/3 raises ExDgraph.Exception for incorrect operation", %{conn: conn} do
    assert_raise Error, fn ->
      ExDgraph.alter!(conn, %{})
    end
  end
end
