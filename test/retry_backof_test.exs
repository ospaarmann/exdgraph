defmodule Retry.Backoff.Test do
  use ExUnit.Case, async: true
  import Stream

  use Retry

  setup_all do
    {:ok, [conn: ExDgraph.conn()]}
  end

  test "retry retries execution for specified attempts using an invalid GraphQL+ query",
       context do
    conn = context[:conn]

    {elapsed, _} =
      :timer.tc(fn ->
        {:error, [code: 2, message: message ]}
        =retry with: lin_backoff(500, 1) |> take(5) do
            ExDgraph.query(conn, "INVALID")
          end
        assert message =~ "while lexing INVALID: Invalid operation type: INVALID"
      end)

    assert elapsed / 1000 >= 2500
  end
end
