defmodule ExDgraph.Protocol do
  @moduledoc """
  Implements callbacks required by DBConnection.

  Each callback receives an open connection as a state.
  """

  use DBConnection
  use Retry

  require Logger

  alias ExDgraph.Api
  alias ExDgraph.{MutationStatement, OperationStatement, QueryStatement}

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
  def handle_execute(query, params, opts, channel) do
    # only try to reconnect if the error is about the broken connection
    with {:disconnect, _, _} <- execute(query, params, opts, channel) do
      [
        delay: delay,
        factor: factor,
        tries: tries
      ] = ExDgraph.config(:retry_linear_backoff)

      delay_stream =
        delay
        |> lin_backoff(factor)
        |> cap(ExDgraph.config(:timeout))
        |> Stream.take(tries)

      retry with: delay_stream do
        with {:ok, channel} <- connect([]),
             {:ok, channel} <- checkout(channel) do
          execute(query, params, opts, channel)
        end
      end
    end
  end

  def handle_info(msg, state) do
    Logger.error(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received unexpected message: " | inspect(msg)]
    end)

    {:ok, state}
  end

  defp execute(%QueryStatement{statement: statement}, params, _, channel) do
    request = ExDgraph.Api.Request.new(query: statement)

    case ExDgraph.Api.Dgraph.Stub.query(channel, request) do
      {:ok, res} -> {:ok, res, channel}
    end
  rescue
    e ->
      {:error, e}
  end

  defp execute(%MutationStatement{statement: statement}, params, _, channel) do
    # Build request
    request = ExDgraph.Api.Mutation.new(set_nquads: statement, commit_now: true)

    case ExDgraph.Api.Dgraph.Stub.mutate(channel, request) do
      {:ok, res} -> {:ok, res, channel}
    end
  rescue
    e ->
      {:error, e}
  end

  defp execute(%OperationStatement{drop_all: drop_all, schema: schema, drop_attr: drop_attr}, params, _, channel) do
    operation = Api.Operation.new(drop_all: drop_all, schema: schema, drop_attr: drop_attr)
    case ExDgraph.Api.Dgraph.Stub.alter(channel, operation) do
      {:ok, res} -> {:ok, res, channel}
    end
  rescue
    e ->
      {:error, e}
  end
end
