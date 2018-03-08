defmodule MutationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  import ExDgraph.TestHelper
  alias ExDgraph.Api.Operation

  alias ExDgraph.Utils

  setup_all do
    conn = ExDgraph.conn()
    drop_all()
    import_starwars_sample()

    on_exit(fn ->
      # close channel ?
      :ok
    end)

    [conn: conn]
  end

  test "mutation/2 returns {:ok, mutation_msg} for correct mutation", %{conn: conn} do
    {status, mutation_msg} = ExDgraph.mutation(conn, starwars_creation_mutation())
    assert status == :ok
    assert mutation_msg.context.aborted == false
  end

  test "mutation/2 returns {:error, error} for incorrect mutation", %{conn: conn} do
    {status, error} = ExDgraph.mutation(conn, "wrong")
    assert status == :error
    assert error[:code] == 2
  end
end
