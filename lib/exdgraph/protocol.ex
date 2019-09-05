defmodule ExDgraph.Protocol do
  @moduledoc """
  Implements callbacks required by DBConnection.
  """

  use DBConnection

  require Logger

  alias ExDgraph.{
    Api,
    Error,
    Exception,
    MutationStatement,
    OperationStatement,
    Query
  }

  alias GRPC.Stub

  defstruct [
    :opts,
    :channel,
    :connected,
    :txn_context,
    :transaction_status,
    txn_aborted?: false
  ]

  @impl true
  def connect(opts) do
    opts = default_opts(opts)

    host = to_charlist(opts[:hostname])
    port = normalize_port(opts[:port])

    # TODO: with statement?
    case gen_stub_options(opts) do
      {:ok, stub_opts} ->
        case Stub.connect("#{host}:#{port}", stub_opts) do
          {:ok, channel} ->
            state = %__MODULE__{opts: opts, channel: channel}
            {:ok, state}

          {:error, reason} ->
            {:error, %Error{action: :connect, reason: reason}}
        end

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

  @doc false
  def handle_info(msg, state) do
    Logger.error(fn ->
      [inspect(__MODULE__), ?\s, inspect(self()), " received unexpected message: " | inspect(msg)]
    end)

    {:ok, state}
  end

  @impl true
  def handle_prepare(query, _opts, %{txn_context: txn_context} = state) do
    {:ok, %{query | txn_context: txn_context}, state}
  end

  @impl true
  def handle_execute(
        %Query{statement: statement} = query,
        _request,
        _opts,
        %{channel: channel, opts: opts} = state
      ) do
    request = ExDgraph.Api.Request.new(query: statement)

    case ExDgraph.Api.Dgraph.Stub.query(channel, request, timeout: opts[:timeout]) do
      {:ok, res} ->
        {:ok, query, res, state}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, state}
  end

  @impl true
  def handle_execute(
        %MutationStatement{statement: statement, set_json: ""} = query,
        _params,
        _,
        state
      ) do
    dgraph_query = ExDgraph.Api.Mutation.new(set_nquads: statement, commit_now: true)
    do_mutate(state, dgraph_query, query)
  end

  @impl true
  def handle_execute(
        %MutationStatement{statement: "", set_json: set_json} = query,
        _params,
        _,
        state
      ) do
    dgraph_query = ExDgraph.Api.Mutation.new(set_json: set_json, commit_now: true)
    do_mutate(state, dgraph_query, query)
  end

  @impl true
  def handle_execute(
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

  @impl true
  def handle_execute(
        %OperationStatement{drop_all: drop_all, schema: schema, drop_attr: drop_attr} = query,
        _params,
        _,
        %{channel: channel} = state
        %{channel: channel, opts: opts} = state
      ) do
    operation = Api.Operation.new(drop_all: drop_all, schema: schema, drop_attr: drop_attr)

    case ExDgraph.Api.Dgraph.Stub.alter(channel, operation, timeout: opts[:timeout]) do
      {:ok, res} ->
        {:ok, query, res, state}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, state}
  end

  defp do_mutate(%{channel: channel, opts: opts} = state, dgraph_query, query) do
    case ExDgraph.Api.Dgraph.Stub.mutate(channel, dgraph_query, timeout: opts[:timeout]) do
      {:ok, res} ->
        {:ok, query, res, state}

      {:error, f} ->
        raise Exception, code: f.status, message: f.message
    end
  rescue
    e ->
      {:error, e, state}
  end

  @spec default_opts(Keyword.t()) :: Keyword.t()
  defp default_opts(opts \\ []) do
    opts
    |> Keyword.put_new(:hostname, System.get_env("DGRAPH_HOST") || 'localhost')
    |> Keyword.put_new(:port, System.get_env("DGRAPH_PORT") || 9080)
    |> Keyword.put_new(:name, :ex_dgraph)
    |> Keyword.put_new(:timeout, 15_000)
    |> Keyword.put_new(:ssl, false)
    |> Keyword.put_new(:tls_client_auth, false)
    |> Keyword.put_new(:certfile, nil)
    |> Keyword.put_new(:keyfile, nil)
    |> Keyword.put_new(:cacertfile, nil)
    |> Keyword.put_new(:enforce_struct_schema, false)
    |> Keyword.put_new(:keepalive, :infinity)
    # DBConnection config options
    |> Keyword.put_new(:backoff_min, 1_000)
    |> Keyword.put_new(:backoff_max, 30_000)
    |> Keyword.put_new(:backoff_type, :rand_exp)
    |> Keyword.put_new(:pool_size, 5)
    |> Keyword.put_new(:idle_interval, 5_000)
    |> Keyword.put_new(:max_restarts, 3)
    |> Keyword.put_new(:max_seconds, 5)
    |> Keyword.update!(:port, &normalize_port/1)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  def gen_stub_options(opts) do
    adapter_opts = %{http2_opts: %{keepalive: opts[:keepalive]}}
    stub_opts = [adapter_opts: adapter_opts]

    case gen_ssl_config(opts) do
      {:ok, nil} ->
        {:ok, stub_opts}

      {:ok, ssl_config} ->
        {:ok, Keyword.put(stub_opts, :cred, GRPC.Credential.new(ssl: ssl_config))}

      {:error, error} ->
        {:error, error}
    end
  end

  def gen_ssl_config(opts) do
    if opts[:ssl] do
      case opts[:cacertfile] do
        nil ->
          {:error, {:not_provided, :cacertfile}}

        cacertfile ->
          with {:ok, tls_config} <- check_tls(opts) do
            ssl_config = [{:cacertfile, cacertfile} | tls_config]
            ssl_config = for {key, value} <- ssl_config, do: {key, to_charlist(value)}
            {:ok, ssl_config}
          end
      end
    else
      {:ok, nil}
    end
  end

  defp check_tls(opts) do
    case {opts[:certfile], opts[:keyfile]} do
      {nil, nil} -> {:ok, []}
      {_, nil} -> {:error, %Error{action: :connect, reason: {:not_provided, :keyfile}}}
      {nil, _} -> {:error, %Error{action: :connect, reason: {:not_provided, :certfile}}}
      {certfile, keyfile} -> {:ok, [certfile: certfile, keyfile: keyfile]}
    end
  end

  defp configure_ssl(opts) do
    case opts[:ssl] do
      true ->
        add_ssl_file(opts, :cacertfile)

      false ->
        opts
    end
  end

  defp configure_tls_auth(opts) do
    case opts[:tls_client_auth] do
      true ->
        opts
        |> add_ssl_file(:certfile)
        |> add_ssl_file(:keyfile)
        |> add_ssl_file(:certfile)

      false ->
        opts
    end
  end

  defp add_ssl_file(opts, type) do
    path = Keyword.fetch!(opts, type)
    Keyword.put(opts, type, validate_tls_file(type, path))
  end

  defp validate_tls_file(type, path) do
    case File.exists?(path) do
      true ->
        path

      false ->
        raise Exception,
          code: 2,
          message: "SSL configuration error. File #{type} '#{path}' not found"
    end
  end

  defp set_ssl_opts(opts) do
    if opts[:ssl] || opts[:tls_client_auth] do
      ssl_opts =
        opts
        |> configure_ssl()
        |> configure_tls_auth()

      Keyword.put(opts, :cred, GRPC.Credential.new(ssl: ssl_opts))
    else
      opts
    end
  end

  defp normalize_port(port) when is_binary(port), do: String.to_integer(port)
  defp normalize_port(port) when is_integer(port), do: port
end
