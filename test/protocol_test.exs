defmodule ExDgraph.ProtocolTest do
  use ExUnit.Case, async: true
  alias ExDgraph.Error

  test "ssl_connection_errors" do
    opts = [
      backoff_type: :stop,
      ssl: true
    ]

    Process.flag(:trap_exit, true)

    assert {:error,
            %Error{
              action: :connect,
              reason: {:not_provided, :cacertfile}
            }} = ExDgraph.Protocol.connect(opts)
  end
end
