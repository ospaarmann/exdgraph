defmodule ExDgraphTest do
  use ExUnit.Case
  import ExDgraph.TestHelper
  import ExUnit.CaptureLog

  alias ExDgraph.{Error, Query, Result}

  setup_all do
    {:ok, conn} = ExDgraph.start_link()
    ExDgraph.operation(conn, %{drop_all: true})
    import_starwars_sample(conn)

    [conn: conn]
  end

  describe "start_link/1" do
    test "it starts the client" do
      {status, pid} = ExDgraph.start_link()
      assert status == :ok
      assert Process.alive?(pid)
    end

    test "it starts the process in the DBConnection.ConnectionPool" do
      {status, pid} = ExDgraph.start_link()
      assert status == :ok
      assert Process.alive?(pid)
      process_as_map = Process.info(pid) |> Enum.into(%{})
      {ancestor, :init, _} = process_as_map.dictionary[:"$initial_call"]
      assert ancestor == DBConnection.ConnectionPool
    end
  end

  describe "connection" do
    test "connection_errors" do
      Process.flag(:trap_exit, true)
      opts = [backoff_type: :stop, max_restarts: 0, timeout: 500]

      assert capture_log(fn ->
               {:ok, pid} = ExDgraph.start_link([hostname: "non_existing"] ++ opts)
               assert_receive {:EXIT, ^pid, :killed}, 10000
             end) =~
               "** (ExDgraph.Error) connect failed with \"Error when opening connection: :timeout\""

      assert capture_log(fn ->
               {:ok, pid} = ExDgraph.start_link([port: 700] ++ opts)

               assert_receive {:EXIT, ^pid, :killed}, 10000
             end) =~
               "** (ExDgraph.Error) connect failed with \"Error when opening connection: :timeout\""
    end
  end

  describe "Query" do
    @sample_query """
      {
          starwars(func: anyofterms(name, "VI"))
          {
            uid
            name
            release_date
            starring
            {
              name
            }
          }
      }
    """

    test "query/3 with correct query returns {:ok, %Query{}, %Result{}}", %{conn: conn} do
      {status, %Query{} = _query, %Result{} = result} = ExDgraph.query(conn, @sample_query)
      assert status == :ok
      data = result.data
      starwars = List.first(data.starwars)
      assert starwars.name == "Star Wars: Episode VI - Return of the Jedi"
      assert starwars.release_date == "1983-05-25"
      assert length(starwars.starring) == 3
    end

    test "query/3 with wrong query returns {:error, %Error{}}", %{conn: conn} do
      {status, %Error{} = error} = ExDgraph.query(conn, "wrong")
      assert status == :error

      assert %Error{} = error
      assert error.code == 2
      assert error.action == :query
      assert error.reason =~ "Invalid operation type: wrong"
    end

    test "query!/2 with correct query returns query_msg", %{conn: conn} do
      %Result{} = result = ExDgraph.query!(conn, @sample_query)
      data = result.data
      starwars = List.first(data.starwars)
      assert starwars.name == "Star Wars: Episode VI - Return of the Jedi"
      assert starwars.release_date == "1983-05-25"
      assert length(starwars.starring) == 3
    end

    test "query!/2 raises ExDgraph.Exception", %{conn: conn} do
      assert_raise ExDgraph.Error, fn ->
        ExDgraph.query!(conn, "wrong")
      end
    end
  end
end
