defmodule ExDgraphTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

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
