defmodule ExDgraph.Protocol do
  @moduledoc """
  Implements callbacks required by DBConnection.

  Each callback receives an open connection as a state.
  """

  use DBConnection
  use Retry

  require Logger

  alias ExDgraph.Api
  alias ExDgraph.{Exception, MutationStatement, OperationStatement, QueryStatement}

  @doc "Callback for DBConnection.connect/1"
  def connect(_opts) do
    host = to_charlist(ExDgraph.config(:hostname))
    port = ExDgraph.config(:port)

    opts =
      []
      |> set_ssl_opts()
      |> Keyword.put(:adapter_opts, %{http2_opts: %{keepalive: ExDgraph.config(:keepalive)}})

    case GRPC.Stub.connect("#{host}:#{port}", opts) do
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
  def disconnect(_err, _state) do
    :ok
  end

  @doc "Callback for DBConnection.handle_begin/1"
  def handle_begin(_opts, _state) do
  end

  @doc "Callback for DBConnection.handle_rollback/1"
  def handle_rollback(_opts, _state) do
  end

  @doc "Callback for DBConnection.handle_commit/1"
  def handle_commit(_opts, _state) do
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
        |> linear_backoff(factor)
        |> cap(ExDgraph.config(:timeout))
        |> Stream.take(tries)

      retry with: delay_stream do
        with {:ok, channel} <- connect([]),
             {:ok, channel} <- checkout(channel) do
          execute(query, params, opts, channel)
        end
      after
        result -> result
      else
        error -> error
      end
    end
  end

  def handle_info({:gun_up, _pid, _protocol}, state) do
    Logger.debug(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received gun_up from server"]
    end)

    {:ok, state}
  end

  def handle_info({:gun_down, _pid, _protocol, _level, _, _}, state) do
    Logger.debug(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received gun_down from server"]
    end)

    {:ok, state}
  end

  def handle_info(msg, state) do
    Logger.error(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received unexpected message: " | inspect(msg)]
    end)

    {:ok, state}
  end

  defp execute(%QueryStatement{statement: statement}, _params, _, channel) do
    request = ExDgraph.Api.Request.new(query: statement)
    timeout = ExDgraph.config(:timeout)
    case ExDgraph.Api.Dgraph.Stub.query(channel, request, timeout: timeout) do
      {:ok, res} ->
        {:ok, res, channel}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, channel}
  end

  defp execute(%MutationStatement{statement: statement, set_json: ""}, _params, _, channel) do
    request = ExDgraph.Api.Mutation.new(set_nquads: statement, commit_now: true)
    do_mutate(channel, request)
  end

  defp execute(%MutationStatement{statement: "", set_json: set_json}, _params, _, channel) do
    request = ExDgraph.Api.Mutation.new(set_json: set_json, commit_now: true)
    do_mutate(channel, request)
  end

  defp execute(
         %MutationStatement{statement: _statement, set_json: _set_json},
         _params,
         _,
         channel
       ) do
    raise Exception, code: 2, message: "Both set_json and statement defined"
  rescue
    e ->
      {:error, e, channel}
  end

  defp execute(
         %OperationStatement{drop_all: drop_all, schema: schema, drop_attr: drop_attr},
         _params,
         _,
         channel
       ) do
    operation = Api.Operation.new(drop_all: drop_all, schema: schema, drop_attr: drop_attr)
    timeout = ExDgraph.config(:timeout)
    case ExDgraph.Api.Dgraph.Stub.alter(channel, operation, timeout: timeout) do
      {:ok, res} ->
        {:ok, res, channel}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, channel}
  end

  defp do_mutate(channel, request) do
    timeout = ExDgraph.config(:timeout)
    case ExDgraph.Api.Dgraph.Stub.mutate(channel, request, timeout: timeout) do
      {:ok, res} ->
        {:ok, res, channel}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, channel}
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
