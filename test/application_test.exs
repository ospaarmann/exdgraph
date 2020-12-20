defmodule ApplicationTest do
  use ExUnit.Case

  test "start/2 starts the application" do
    {status, pid} = ExDgraph.Application.start(nil, [])
    assert status == :ok
    assert Process.alive?(pid)
  end

  test "stop/1 returns :ok" do
    res = ExDgraph.Application.stop(%{})
    assert res == :ok
  end
end
