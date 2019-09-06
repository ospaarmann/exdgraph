defmodule ExDgraphTest do
  use ExUnit.Case
  import ExDgraph.TestHelper
  import ExUnit.CaptureLog

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
end
