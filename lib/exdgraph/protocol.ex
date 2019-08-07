defmodule ExDgraph.Protocol do
  @moduledoc """
  Implements callbacks required by DBConnection.
  """

  use DBConnection
  use Retry

  require Logger

  alias ExDgraph.{
    Adapter,
    Api,
    Error,
    Exception,
    MutationStatement,
    OperationStatement,
    QueryStatement
  }

  defstruct [
    :adapter,
    :channel,
    :connected,
    :txn_context,
    :transaction_status,
    txn_aborted?: false
  ]

  @impl true
  def connect(_opts) do
    host = to_charlist(ExDgraph.config(:hostname))
    port = ExDgraph.config(:port)

    opts =
      []
      |> set_ssl_opts()
      |> Keyword.put(:adapter_opts, %{http2_opts: %{keepalive: ExDgraph.config(:keepalive)}})

    case Adapter.connect(host, port, opts) do
      {:ok, channel} ->
        state = %__MODULE__{channel: channel}
        {:ok, state}

      {:error, reason} ->
        {:error, %Error{action: :connect, reason: reason}}
    end
  end

  @impl true
  def checkout(state) do
    {:ok, state}
  end

  @impl true
  def checkin(state) do
    {:ok, state}
  end

  @impl true
  def disconnect(_error, %{channel: channel} = _state) do
    case GRPC.Stub.disconnect(channel) do
      {:ok, _} -> :ok
      {:error, _reason} -> :ok
    end
  end

  @impl true
  def ping(%{channel: channel} = state) do
    %{adapter_payload: %{conn_pid: conn_pid}} = channel
    # check if the server is up and wait 5s seconds before disconnect
    stream = :gun.head(conn_pid, "/")
    response = :gun.await(conn_pid, stream, 5_000)

    # return based on response
    case response do
      {:response, :fin, 200, _} -> {:ok, state}
      {:error, reason} -> {:disconnect, reason, state}
      _ -> :ok
    end
  end

  def handle_status(_, %{transaction_status: status} = state) do
    {:idle, state}
  end

  @impl true
  def handle_begin(_opts, _state) do
  end

  @impl true
  def handle_rollback(_opts, _state) do
  end

  @impl true
  def handle_commit(_opts, _state) do
  end

  @impl true
  def handle_execute(query, params, opts, %{channel: channel} = state) do
    # only try to reconnect if the error is about the broken connection
    with {:disconnect, _, _} <- execute(query, params, opts, state) do
      [
        delay: delay,
        factor: factor,
        tries: tries
      ] = ExDgraph.config(:retry_linear_backoff)

      delay_stream =
        delay
        |> linear_backoff(factor)
        |> cap(ExDgraph.config(:timeout))
        |> Stream.take(tries)

      retry with: delay_stream do
        with {:ok, channel} <- connect([]),
             {:ok, channel} <- checkout(channel) do
          execute(query, params, opts, state)
        end
      after
        result -> result
      else
        error -> error
      end
    end
  end

  @doc false
  def handle_info(msg, state) do
    Logger.error(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received unexpected message: " | inspect(msg)]
    end)

    {:ok, state}
  end

  defp execute(
         %QueryStatement{statement: statement} = query,
         _params,
         _,
         %{channel: channel} = state
       ) do
    request = ExDgraph.Api.Request.new(query: statement)
    timeout = ExDgraph.config(:timeout)

    case ExDgraph.Api.Dgraph.Stub.query(channel, request, timeout: timeout) do
      {:ok, res} ->
        {:ok, query, res, state}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, state}
  end

  defp execute(%MutationStatement{statement: statement, set_json: ""} = query, _params, _, state) do
    dgraph_query = ExDgraph.Api.Mutation.new(set_nquads: statement, commit_now: true)
    do_mutate(state, dgraph_query, query)
  end

  defp execute(%MutationStatement{statement: "", set_json: set_json} = query, _params, _, state) do
    dgraph_query = ExDgraph.Api.Mutation.new(set_json: set_json, commit_now: true)
    do_mutate(state, dgraph_query, query)
  end

  defp execute(
         %MutationStatement{statement: _statement, set_json: _set_json},
         _params,
         _,
         %{channel: channel} = state
       ) do
    raise Exception, code: 2, message: "Both set_json and statement defined"
  rescue
    e ->
      {:error, e, state}
  end

  defp execute(
         %OperationStatement{drop_all: drop_all, schema: schema, drop_attr: drop_attr} = query,
         _params,
         _,
         %{channel: channel} = state
       ) do
    operation = Api.Operation.new(drop_all: drop_all, schema: schema, drop_attr: drop_attr)
    timeout = ExDgraph.config(:timeout)

    case ExDgraph.Api.Dgraph.Stub.alter(channel, operation, timeout: timeout) do
      {:ok, res} ->
        {:ok, query, res, state}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, state}
  end

  defp do_mutate(%{channel: channel} = state, dgraph_query, query) do
    timeout = ExDgraph.config(:timeout)

    case ExDgraph.Api.Dgraph.Stub.mutate(channel, dgraph_query, timeout: timeout) do
      {:ok, res} ->
        {:ok, query, res, state}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, state}
  end

  defp configure_ssl(ssl_opts \\ []) do
    case ExDgraph.config(:ssl) do
      true ->
        add_ssl_file(ssl_opts, :cacertfile)

      false ->
        ssl_opts
    end
  end

  defp configure_tls_auth(ssl_opts \\ []) do
    case ExDgraph.config(:tls_client_auth) do
      true ->
        ssl_opts
        |> add_ssl_file(:certfile)
        |> add_ssl_file(:keyfile)
        |> add_ssl_file(:certfile)

      false ->
        ssl_opts
    end
  end

  defp add_ssl_file(ssl_opts \\ [], type) do
    Keyword.put(ssl_opts, type, validate_tls_file(type, ExDgraph.config(type)))
  end

  defp validate_tls_file(type, path) do
    case File.exists?(path) do
      true ->
        path

      false ->
        raise Exception,
          code: 2,
          message: "SSL configuration error. File #{type} '#{ExDgraph.config(type)}' not found"
    end
  end

  defp set_ssl_opts(opts \\ []) do
    if ExDgraph.config(:ssl) || ExDgraph.config(:tls_client_auth) do
      ssl_opts =
        configure_ssl()
        |> configure_tls_auth()

      Keyword.put(opts, :cred, GRPC.Credential.new(ssl: ssl_opts))
    else
      opts
    end
  end
end
