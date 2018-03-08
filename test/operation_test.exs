defmodule OperationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  import ExDgraph.TestHelper

  setup do
    conn = ExDgraph.conn()
    drop_all()
    import_starwars_sample()

    on_exit(fn ->
      # close channel ?
      :ok
    end)

    [conn: conn]
  end

  test "operation(%{drop_all: true}) is successful", %{conn: conn} do
    {status, operation_msg} = ExDgraph.operation(conn, %{drop_all: true})
    assert status == :ok
    assert operation_msg == %ExDgraph.Api.Payload{Data: ""}
  end

  test "operation/2 returns {:error, error} for incorrect operation", %{conn: conn} do
    {status, error} = ExDgraph.operation(conn, %{})
    assert status == :error
    assert error[:code] == 2
  end

  test "operation!(%{drop_all: true}) is successful", %{conn: conn} do
    operation_msg = ExDgraph.operation!(conn, %{drop_all: true})
    assert operation_msg == %ExDgraph.Api.Payload{Data: ""}
  end

  test "operation!/2 raises ExDgraph.Exception for incorrect operation", %{conn: conn} do
    assert_raise ExDgraph.Exception, fn ->
      ExDgraph.operation!(conn, %{})
    end
  end
end
