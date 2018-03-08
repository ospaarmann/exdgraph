defmodule ApplicationTest do
  use ExUnit.Case

  test "Make sure the application is running" do
    res = Application.ensure_started(:ex_dgraph)
    assert res == :ok
    cnf = ExDgraph.Utils.default_config()
    {state, {message, _}} = ExDgraph.Application.start(%{}, cnf)
    assert state == :error
    assert message == :already_started
  end

  test "stop/1 returns :ok" do
    res = ExDgraph.Application.stop(%{})
    assert res == :ok
  end
end
