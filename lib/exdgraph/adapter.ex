defmodule ExDgraph.Adapter do
  alias ExDgraph.Api.Dgraph.Stub, as: ApiStub
  alias ExDgraph.Error

  require Logger

  def connect(host, port, opts \\ []) do
    case GRPC.Stub.connect("#{host}:#{port}", opts) do
      {:ok, channel} ->
        {:ok, channel}

      {:error, reason} ->
        {:error, %Error{action: :connect, reason: reason}}
    end
  end
end
