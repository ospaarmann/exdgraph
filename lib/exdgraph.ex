defmodule ExDgraph do
  @moduledoc """
  ExDgraph is a gRPC based client for the Dgraph database. It uses DBConnection to support transactions and connection pooling. Works with Dgraph v1.0.16 (latest).

  ## Installation

  Add the package `ex_dgraph` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:ex_dgraph, "~> 0.2.0-beta.3"}
    ]
  end
  ```

  And add the application to your list of applications in `mix.exs`:

  ```elixir
  def application do
    [
      applications: [
        :ex_dgraph
      ]
    ]
  end
  ```

  Then, update your dependencies:

  ```
  $ mix deps.get
  ```

  ### Usage with Phoenix

  Add the configuration to your respective configuration file:

  ```elixir
  config :ex_dgraph, ExDgraph,
    hostname: 'localhost',
    port: 9080,
    pool_size: 5,
    keepalive: :infinity
  ```

  The available configuration options are:

  ```elixir
  config :ex_dgraph, ExDgraph,
    hostname: 'localhost',
    port: 9080,
    pool_size: 5,
    timeout: 15_000, # This value is used for the DBConnection timeout and the GRPC client deadline
    ssl: false,
    tls_client_auth: false,
    certfile: nil,
    keyfile: nil,
    cacertfile: nil,
    retry_linear_backoff: {delay: 150, factor: 2, tries: 3},
    keepalive: infinity
  ```

  And finally don't forget to add ExDgraph to the supervisor tree of your app:

  ```elixir
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      {ExDgraph, Application.get_env(:ex_dgraph, ExDgraph)},
      supervisor(MyApp.Endpoint, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
  ```

  ## Usage

  I recommend installing and running Dgraph locally with Docker. You find information on how to do that [here](https://docs.dgraph.io/get-started/#from-docker-image). To use this simple example you first have to [import the example data](https://docs.dgraph.io/get-started/#step-3-run-queries). You can just open [http://localhost:8000](http://localhost:8000) in your browser when Dgraph is running to execute and visualize queries using Ratel.

  At the moment simple queries, mutations and operations are supported. And to make things easier ExDgraph returns an Elixir map and you can also just insert a map. This allows you to insert a complex dataset with vertices and edges in one call. To make things even better: If there is a `uid` present anywhere in the map the record isn't inserted but updated. This way you can update and add records in one go.

  Also check the tests for more examples.

  ### Example for a query

  ```elixir
  query = \"\"\"
    {
        starwars(func: anyofterms(name, "VI"))
        {
          uid
          name
          release_date
          starring
          {
            name
          }
        }
    }
  \"\"\"

  conn = ExDgraph.conn()
  {:ok, msg} = ExDgraph.query(conn, query)
  ```

  ### Examples for a mutation

  ```elixir

  starwars_schema = "id: string @index(exact).
      name: string @index(exact, term) @count .
      age: int @index(int) .
      friend: uid @count .
      dob: dateTime ."

  starwars_creation_mutation = \"\"\"
     _:luke <name> "Luke Skywalker" .
     _:leia <name> "Princess Leia" .
     _:han <name> "Han Solo" .
     _:lucas <name> "George Lucas" .
     _:irvin <name> "Irvin Kernshner" .
     _:richard <name> "Richard Marquand" .

     _:sw1 <name> "Star Wars: Episode IV - A New Hope" .
     _:sw1 <release_date> "1977-05-25" .
     _:sw1 <revenue> "775000000" .
     _:sw1 <running_time> "121" .
     _:sw1 <starring> _:luke .
     _:sw1 <starring> _:leia .
     _:sw1 <starring> _:han .
     _:sw1 <director> _:lucas .

     _:sw2 <name> "Star Wars: Episode V - The Empire Strikes Back" .
     _:sw2 <release_date> "1980-05-21" .
     _:sw2 <revenue> "534000000" .
     _:sw2 <running_time> "124" .
     _:sw2 <starring> _:luke .
     _:sw2 <starring> _:leia .
     _:sw2 <starring> _:han .
     _:sw2 <director> _:irvin .

     _:sw3 <name> "Star Wars: Episode VI - Return of the Jedi" .
     _:sw3 <release_date> "1983-05-25" .
     _:sw3 <revenue> "572000000" .
     _:sw3 <running_time> "131" .
     _:sw3 <starring> _:luke .
     _:sw3 <starring> _:leia .
     _:sw3 <starring> _:han .
     _:sw3 <director> _:richard .

     _:st1 <name> "Star Trek: The Motion Picture" .
     _:st1 <release_date> "1979-12-07" .
     _:st1 <revenue> "139000000" .
     _:st1 <running_time> "132" .
  \"\"\"

  conn = ExDgraph.conn()
  {:ok, operation_msg} = ExDgraph.operation(conn, %{schema: starwars_schema})
  {:ok, mutation_msg} = ExDgraph.mutation(conn, starwars_creation_mutation)

  ```

  ### Example for inserting a map

  ```elixir
  map = %{
    name: "Alice",
    friends: %{
      name: "Betty"
    }
  }

  conn = ExDgraph.conn()
  ExDgraph.set_map(conn, map)
  {:ok, mutation_msg} = ExDgraph.set_map(conn, map)
  ```

  `ExDgraph.set_map/2` returns the data you have passed it but populates every node in your map with the respective uids returned from Dgraph. For example:

  ```elixir
  %{
    context: %ExDgraph.Api.TxnContext{
      aborted: false,
      commit_ts: 1703,
      keys: [],
      lin_read: %ExDgraph.Api.LinRead{ids: %{1 => 1508}},
      start_ts: 1702
    },
    result: %{
      friends: [%{name: "Betty", uid: "0xd82"}],
      name: "Alice",
      uid: "0xd81"
    },
    uids: %{
      "763d617a-af34-4ff9-9863-e072bf85146d" => "0xd82",
      "e94713a5-54a7-4e36-8ab8-0d3019409892" => "0xd81"
    }
  }
  ```

  You can also use `ExDgraph.set_map/2` to update an existing node or add new edges by passing a `uid` in your map:

  ```elixir
  user = %{name: "bob", occupation: "dev"}
  {:ok, res} = ExDgraph.set_map(conn, user)

  other_mutation = %{
    uid: res.result.uid,
    friends: [%{name: "Paul", occupation: "diver"}, %{name: "Lisa", occupation: "consultant"}]
  }

  {:ok, res2} = ExDgraph.set_map(conn, other_mutation)

  # Content of res2. As you can see the original user has been updated.

  %{
    context: %ExDgraph.Api.TxnContext{
      aborted: false,
      commit_ts: 3271,
      keys: [],
      lin_read: %ExDgraph.Api.LinRead{ids: %{1 => 2905}},
      start_ts: 3270
    },
    result: %{
      friends: [
        %{name: "Paul", occupation: "diver", uid: "0x19c6"},
        %{occupation: "consultant", name: "Lisa", uid: "0x19c7"}
      ],
      uid: "0x19c5"
    },
    uids: %{
      "7086397d-aa39-4257-a70e-3ad4e63abc14" => "0x19c7",
      "a66d77fa-afc0-478f-b838-ea1a97a20c11" => "0x19c6"
    }
  }
  ```

  ### Examples for an operation

  ```elixir
  # Connect
  conn = ExDgraph.conn()

  # Drop all entries from the database
  ExDgraph.operation(conn, %{drop_all: true})

  # Create schema
  @testing_schema "id: string @index(exact).
    name: string @index(exact, term) @count .
    age: int @index(int) .
    friend: uid @count .
    dob: dateTime ."

  # Run operation
  ExDgraph.operation(conn, %{schema: @testing_schema})
  ```

  ### Example for a raw query

  This is an example on how to use the Protobuf API with GRPC directly and how to extend the library.

  ```elixir
  # Connect to Server
  {:ok, channel} = GRPC.Stub.connect("#localhost:9080")

  # Define query (for now just a string)
  query = \"\"\"
    {
        starwars(func: anyofterms(name, "VI"))
        {
          uid
          name
          release_date
          starring
          {
            name
          }
        }
    }
  \"\"\"

  # Build request
  request = ExDgraph.Api.Request.new(query: query)

  # Send request to server
  {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)

  # Parse result
  json = Jason.decode!(msg.json)
  ```

  ## Using SSL

  If you want to connect to Dgraph using SSL you have to set the `:ssl` config to `true` and provide a certificate:

  ```elixir
  config :ex_dgraph, ExDgraph,
    # default port considered to be: 9080
    hostname: 'localhost',
    pool_size: 5,
    ssl: true,
    cacertfile: '/path/to/MyRootCA.pem'
  ```

  You also have to provide the respective certificates and key to the server and start it with the following options:

  ```
  command: dgraph server --my=server:7080 --memory_mb=2048 --zero=zero:5080 --tls_on --tls_ca_certs=/path/to/cert/in/container/MyRootCA.pem --tls_cert=/path/to/cert/in/container/MyServer1.pem --tls_cert_key=/path/to/cert/in/container/MyServer1.key
  ```

  You can read more about how to create self-signed certificates in the [Wiki](https://github.com/ospaarmann/exdgraph/wiki).

  ## Using TLS client authentication
  If you want to connect to Dgraph and authenticate the client via TLS you have to set the `:tls_client_auth` config to `true` and provide certificates and key:

  ```elixir
  config :ex_dgraph, ExDgraph,
    # default port considered to be: 9080
    hostname: 'localhost',
    pool_size: 5,
    ssl: true,
    cacertfile: '/path/to/MyRootCA.pem',
    certfile: '/path/to/MyClient1.pem',
    keyfile: '/path/to/MyClient1.key',
  ```

  You also have to provide the respective certificates and key to the server and start it with the following options:

  ```
  command: dgraph server --my=server:7080 --memory_mb=2048 --zero=zero:5080 --tls_on --tls_ca_certs=/path/to/cert/in/container/MyRootCA.pem --tls_cert=/path/to/cert/in/container/MyServer1.pem --tls_cert_key=/path/to/cert/in/container/MyServer1.key --tls_client_auth=REQUIREANDVERIFY
  ```

  You can read more about how to create self-signed certificates in the [Wiki](https://github.com/ospaarmann/exdgraph/wiki).
  """

  use Supervisor

  # alias ExDgraph.Api
  alias ExDgraph.{Operation, Mutation, Protocol, Query}

  @type conn :: DBConnection.conn()
  # @type transaction :: DBConnection.t()

  @pool_name :ex_dgraph

  # Inherited from DBConnection

  @idle_timeout 5_000
  @timeout 15_000

  @doc """
  Start the connection process and connect to Dgraph

  ## Options:
    - `:hostname` - Server hostname (default: DGRAPH_HOST env variable, then localhost);
    - `:port` - Server port (default: DGRAPH_PORT env variable, then 9080);
    - `:username` - Username;
    - `:password` - User password;
    - `:pool_size` - maximum pool size;
    - `:timeout` - Connect timeout in milliseconds (default: `#{@timeout}`) for  DBConnection and the GRPC client deadline.
    - `:idle_timeout` - Idle timeout to ping database to maintain a connection
      (default: `#{@idle_timeout}`)
    - `:ssl` - If to use ssl for the connection (please see configuration example).
      If you set this option, you also have to set `cacertfile` to the correct path.
    - `:tls_client_auth` - If to use TLS client authentication for the connection
      (please see configuration example). If you set this option, you also have to set
      `certfile`, `keyfile` and `cacertfile` to the correct path.
    - `:certfile` - Path to your client certificate.
    - `:keyfile` - Path to your client key.
    - `:cacertfile` - Path to your CA certificate you used to sign the certificate and key.
      Check the Wiki on how to set this up.
    - `:retry_linear_backoff` - Retry options. Defaults to `{delay: 150, factor: 2, tries: 3}`
    - `:keepalive` - Time in ms between pings to the server. Default value is `:infinity` which disables pings completely. Dgraph drops the connection on pings atm so it is disabled for now.

  ## Example of valid configurations (i.e. defined in config/dev.exs) and usage:

      config :ex_dgraph, ExDgraph,
        hostname: 'localhost',
        port: 9080,
        pool_size: 5

  ## With SSL

      config :ex_dgraph, ExDgraph,
        # default port considered to be: 9080
        hostname: 'localhost',
        pool_size: 5,
        ssl: true,
        cacertfile: '/path/to/MyRootCA.pem'

  ## With TLS client authentication

      config :ex_dgraph, ExDgraph,
        # default port considered to be: 9080
        hostname: 'localhost',
        pool_size: 5,
        ssl: true,
        cacertfile: '/path/to/MyRootCA.pem',
        certfile: '/path/to/MyClient1.pem',
        keyfile: '/path/to/MyClient1.key',

  ## Example

      iex> opts = Application.get_env(:ex_dgraph, ExDgraph)
      {:ok, pid} = ExDgraph.start_link(opts)
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    DBConnection.start_link(Protocol, opts)
  end

  @doc """
  Returns a pool name which can be used to acquire a connection.
  """
  def conn, do: pool_name()

  @doc false
  def pool_name, do: @pool_name

  ## Query
  ########################

  @doc """
  Sends the query to the server and returns `{:ok, result}` or
  `{:error, error}` otherwise.

  ## Parameters

  - `conn`: The pool name from `ExDgraph.conn()`.
  - `statement`: A GraphQL+ query statement as a string.

  ## Examples

  ```elixir
  query_statement = \"\"\"
    {
       starwars(func: anyofterms(name, "VI"))
       {
         uid
         name
         release_date
         starring
         {
           name
         }
       }
     }
  \"\"\"
  ```

      iex> ExDgraph.query(conn, query_statement)
      %{:ok,
        %{
          result: %{
            starwars: [
              %{
                name: "Star Wars: Episode VI - Return of the Jedi",
                release_date: "1983-05-25",
                starring: [
                  %{name: "Princess Leia"},
                  %{name: "Luke Skywalker"},
                  %{name: "Han Solo"}
                ],
                uid: "0xcdce"
              }
            ]
          },
          schema: [],
          txn: %ExDgraph.Api.TxnContext{
            aborted: false,
            commit_ts: 0,
            keys: [],
            lin_read: %ExDgraph.Api.LinRead{ids: %{1 => 5696}},
            start_ts: 51357
          }
        }
      }

      iex> ExDgraph.query(conn, invalid_statement)
      {:error, [code: 2, message: "while lexing invalid_statement: Invalid operation type: invalid_statement"]}

  """
  @spec query(conn, iodata, map, Keyword.t()) :: {:ok, map} | {:error, ExDgraph.Error.t() | term}
  def query(conn, statement, parameters \\ %{}, opts \\ []) do
    query = %Query{statement: statement}

    with {:ok, %Query{} = query, result} <-
           DBConnection.prepare_execute(conn, query, parameters, opts),
         do: {:ok, query, result}
  end

  @doc """
  The same as `query/3` but raises a ExDgraph.Error if it fails.
  Returns the server response otherwise.
  """
  @spec query!(conn, String.t()) :: ExDgraph.QueryResult | ExDgraph.Error
  def query!(conn, statement, opts \\ []) do
    case query(conn, statement, opts) do
      {:ok, _query, result} ->
        result

      {:error, error} ->
        raise error
    end
  end

  ## Mutation
  ######################

  @doc """
  Sends the mutation to the server and returns `{:ok, query, result}` or
  `{:error, error}` otherwise

  ## Examples

  ```elixir
  starwars_creation_mutation = \"\"\"
     _:luke <name> "Luke Skywalker" .
     _:leia <name> "Princess Leia" .
     _:han <name> "Han Solo" .
     _:lucas <name> "George Lucas" .
     _:irvin <name> "Irvin Kernshner" .
     _:richard <name> "Richard Marquand" .

     _:sw1 <name> "Star Wars: Episode IV - A New Hope" .
     _:sw1 <release_date> "1977-05-25" .
     _:sw1 <revenue> "775000000" .
     _:sw1 <running_time> "121" .
     _:sw1 <starring> _:luke .
     _:sw1 <starring> _:leia .
     _:sw1 <starring> _:han .
     _:sw1 <director> _:lucas .

     _:sw2 <name> "Star Wars: Episode V - The Empire Strikes Back" .
     _:sw2 <release_date> "1980-05-21" .
     _:sw2 <revenue> "534000000" .
     _:sw2 <running_time> "124" .
     _:sw2 <starring> _:luke .
     _:sw2 <starring> _:leia .
     _:sw2 <starring> _:han .
     _:sw2 <director> _:irvin .

     _:sw3 <name> "Star Wars: Episode VI - Return of the Jedi" .
     _:sw3 <release_date> "1983-05-25" .
     _:sw3 <revenue> "572000000" .
     _:sw3 <running_time> "131" .
     _:sw3 <starring> _:luke .
     _:sw3 <starring> _:leia .
     _:sw3 <starring> _:han .
     _:sw3 <director> _:richard .

     _:st1 <name> "Star Trek: The Motion Picture" .
     _:st1 <release_date> "1979-12-07" .
     _:st1 <revenue> "139000000" .
     _:st1 <running_time> "132" .
  \"\"\"
  ```

      iex> ExDgraph.mutate(conn, starwars_creation_mutation)
      %{:ok,
        query,
        %{
          context: %ExDgraph.Api.TxnContext{
            aborted: false,
            commit_ts: 60012,
            keys: [],
            lin_read: %ExDgraph.Api.LinRead{ids: %{1 => 6406}},
            start_ts: 60011
          },
          uids: %{
            "han" => "0xea7e",
            "irvin" => "0xea79",
            "leia" => "0xea7d",
            "lucas" => "0xea78",
            "luke" => "0xea77",
            "richard" => "0xea7a",
            "st1" => "0xea76",
            "sw1" => "0xea7b",
            "sw2" => "0xea7c",
            "sw3" => "0xea75"
          }
        }
      }

  """
  @spec mutate(conn, iodata | map() | struct(), Keyword.t()) ::
          {:ok, map()} | {:ok, ExDgraph.MutationResult} | {:error, ExDgraph.Error.t() | term}
  def mutate(conn, query, opts \\ [])

  def mutate(conn, query, opts) do
    mutation = %Mutation{statement: query}

    with {:ok, %Mutation{} = _query, result} <-
           DBConnection.prepare_execute(conn, mutation, %{}, opts),
         do: {:ok, query, result}
  end

  @doc """
  The same as `mutate/3` but raises a ExDgraph.Error if it fails.
  Returns the server response otherwise.
  """
  @spec mutate(conn, iodata | map() | struct(), Keyword.t()) ::
          ExDgraph.MutationResult | ExDgraph.Error.t()
  def mutate!(conn, statement, opts \\ []) do
    case mutate(conn, statement, opts) do
      {:ok, _query, result} ->
        result

      {:error, error} ->
        raise error
    end
  end

  ## Operation
  ######################

  @doc """
  Sends the operations to the server and returns `{:ok, result}` or
  `{:error, error}` otherwise

  ## Examples

  ### Create schema

  ```elixir
  schema = \"\"\"
    id: string @index(exact).
    name: string @index(exact, term) @count .
    age: int @index(int) .
    friend: uid @count .
    dob: dateTime .
  \"\"\"
  ```
      iex> ExDgraph.operation(conn, %{schema: schema})
      %{:ok, %ExDgraph.Api.Payload{Data: ""}}

  ### Drop all entries from the database

      iex> ExDgraph.operation(conn, %{drop_all: true})
      %{:ok, %ExDgraph.Api.Payload{Data: ""}}

  """
  @spec alter(conn, iodata | map, Keyword.t()) :: {:ok, map} | {:error, ExDgraph.Error.t() | term}
  def alter(conn, query, opts \\ [])

  def alter(conn, query, opts) when is_binary(query) do
    operation = %Operation{schema: query}

    with {:ok, %Operation{} = _operation, result} <-
           DBConnection.prepare_execute(conn, operation, %{}, opts),
         do: {:ok, query, result}
  end

  @spec alter(conn, iodata | map, Keyword.t()) :: {:ok, map} | {:error, ExDgraph.Error.t() | term}
  def alter(conn, query, opts) when is_map(query) do
    operation = struct(Operation, query)

    with {:ok, %Operation{} = _operation, result} <-
           DBConnection.prepare_execute(conn, operation, %{}, opts),
         do: {:ok, query, result}
  end

  @doc """
  The same as `alter/3` but raises a ExDgraph.Exception if it fails.
  Returns the server response otherwise.
  """
  @spec alter!(conn, String.t(), Keyword.t()) :: ExDgraph.Payload | ExDgraph.Error
  def alter!(conn, query, opts \\ []) do
    case alter(conn, query, opts) do
      {:ok, _query, payload} ->
        payload

      {:error, error} ->
        raise error
    end
  end
end
