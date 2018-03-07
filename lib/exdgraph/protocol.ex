defmodule ExDgraph.Protocol do
  @moduledoc """
  Implements callbacks required by DBConnection.

  Each callback receives an open connection as a state.
  """

  use DBConnection
  use Retry

  require Logger

  @doc "Callback for DBConnection.connect/1"
  def connect(_opts) do
    case GRPC.Stub.connect("localhost:9080") do
      {:ok, channel} ->
        {:ok, channel}

      _ ->
        Logger.error("ExDgraph: Connection Failed")
        {:error, ExDgraph.Error}
        # TODO: Proper error handling
    end
  end

  @doc "Callback for DBConnection.checkout/1"
  def checkout(state) do
    {:ok, state}
    # TODO: Proper checkout. Only placeholder callback
  end

  @doc "Callback for DBConnection.checkin/1"
  def checkin(state) do
    {:ok, state}
    # TODO: Proper checkout. Only placeholder callback
  end

  @doc "Callback for DBConnection.disconnect/1"
  def disconnect(_err, state) do
  end

  @doc "Callback for DBConnection.handle_begin/1"
  def handle_begin(_opts, state) do
  end

  @doc "Callback for DBConnection.handle_rollback/1"
  def handle_rollback(_opts, state) do
  end

  @doc "Callback for DBConnection.handle_commit/1"
  def handle_commit(_opts, state) do
  end

  @doc "Callback for DBConnection.handle_execute/1"
  def handle_execute(query, params, opts, state) do
  end

  def handle_info(msg, state) do
    Logger.error(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received unexpected message: " | inspect(msg)]
    end)

    {:ok, state}
  end
end
