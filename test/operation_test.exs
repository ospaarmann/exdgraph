defmodule OperationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  import ExDgraph.TestHelper
  alias ExDgraph.Api.Operation

  alias ExDgraph.Utils

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
end
