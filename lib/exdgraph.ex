defmodule ExDgraph do
  @moduledoc """
  ExDgraph is a gRPC based client for the Dgraph database. It uses the DBConnection behaviour to support transactions and connection pooling via Poolboy. Works with Dgraph v1.0.4 (latest).

  ## Installation

  Add the package `ex_dgraph` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [
      {:ex_dgraph, "~> 0.2.0-alpha.3"}
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
    max_overflow: 1
  ```

  The available configuration options are:

  ```elixir
  config :ex_dgraph, ExDgraph,
    hostname: 'localhost',
    port: 9080,
    pool_size: 5,
    max_overflow: 1
    timeout: 15_000,
    pool: DBConnection.Poolboy,
    ssl: false,
    tls_client_auth: false,
    certfile: nil,
    keyfile: nil,
    cacertfile: nil,
    retry_linear_backoff: {delay: 150, factor: 2, tries: 3}
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

  **Important:** Please also note the instructions further down on how to run ExDgraph with Phoenix 1.3. It requires Cowboy 2 which means you have to change some things.

  ## Usage

  Again, this is work in progress. I'll add more examples on how to use this on the go. So far you can connect to a server and run a simple query. I recommend installing and running Dgraph locally with Docker. You find information on how to do that [here](https://docs.dgraph.io/get-started/#from-docker-image). To use this simple example you first have to [import the example data](https://docs.dgraph.io/get-started/#step-3-run-queries). You can just open [http://localhost:8000](http://localhost:8000) in your browser when Dgraph is running to execute and visualize queries using Ratel.

  At the moment simple queries, mutations and operations are supported via the DBConnection behaviour. Everything else is done directly via the Protobuf API. This will change. Check the tests for examples.

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
  json = Poison.decode!(msg.json)
  ```

  ## Using with Phoenix 1.3
  Since grpc-elixir needs Cowboy 2 you need to upgrade your Phoenix app to work with Cowboy 2.

  ### Update dependencies in your mix.exs

  Open up the mix.exs file and replace the dependencies with this:

  ```elixir
  defp deps do
    [
      {:phoenix, git: "https://github.com/phoenixframework/phoenix", branch: "master", override: true},
      {:plug, git: "https://github.com/elixir-plug/plug", branch: "master", override: true},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 2.1", override: true},
      {:ex_dgraph, "~> 0.1.0", github: "ospaarmann/exdgraph", branch: "master"}
    ]
  end
  ```

  Run `mix deps.get` to retrieve the new dependencies.

  ### Create a self-signed certificate for https

  We will need to do this as, although http2 does not specifically require it, browser do expect http2 connections to be secured over TLS.

  In your project folder run:

  ```
  openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" -keyout priv/server.key -out priv/server.pem
  ```

  Add the two generated files to .gitignore.

  Now we will need to adjust the Endpoint configuration to use a secure connection and use a Cowboy 2 handler

  Replace the configuration with the following.

  ```elixir
  config :my_app, MyAppWeb.Endpoint,
    debug_errors: true,
    handler: Phoenix.Endpoint.Cowboy2Handler,
    code_reloader: true,
    check_origin: false,
    watchers: [],
    https: [port: 4000, keyfile: "priv/server.key", certfile: "priv/server.pem"]
  ```

  This tells phoenix to listen on port 4000 with the just generated certificate. Furthermore, the handler tells Phoenix to use Cowboy2.

  If you now start the application with `mix phx.server` and go to https://localhost:4000 the browser will tell that the connection is not secure with for example NET::ERR_CERT_AUTHORITY_INVALID. This is because the certificate is self signed, and not by a certificate authority. You can open the certificate in for example Keychain on Mac OS X and tell your OS to trust the certificate.

  *[Source](https://maartenvanvliet.nl/2017/12/15/upgrading_phoenix_to_http2/)*

  ## Using SSL
  If you want to connect to Dgraph using SSL you have to set the `:ssl` config to `true` and provide a certificate:

  ```elixir
  config :ex_dgraph, ExDgraph,
    # default port considered to be: 9080
    hostname: 'localhost',
    pool_size: 5,
    max_overflow: 1,
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
    max_overflow: 1,
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

  @pool_name :ex_dgraph_pool
  @timeout 15_000

  alias ExDgraph.Api.{Dgraph, Request, Response, Mutation, Operation}
  alias ExDgraph.{ConfigAgent, Operation, Mutation, Query, Utils}

  @type conn :: DBConnection.conn()
  # @type transaction :: DBConnection.t()

  @doc """
  Start the connection process and connect to Dgraph

  ## Options:
    - `:hostname` - Server hostname (default: DGRAPH_HOST env variable, then localhost);
    - `:port` - Server port (default: DGRAPH_PORT env variable, then 9080);
    - `:username` - Username;
    - `:password` - User password;
    - `:pool_size` - maximum pool size;
    - `:max_overflow` - maximum number of workers created if pool is empty
    - `:timeout` - Connect timeout in milliseconds (default: `#{@timeout}`)
       Poolboy will block the current process and wait for an available worker,
       failing after a timeout, when the pool is full;
    - `:pool` - The connection pool. Defaults to `DbConnection.Poolboy`.
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

  ## Example of valid configurations (i.e. defined in config/dev.exs) and usage:

      config :ex_dgraph, ExDgraph,
        hostname: 'localhost',
        port: 9080,
        pool_size: 5,
        max_overflow: 1

  ## With SSL

      config :ex_dgraph, ExDgraph,
        # default port considered to be: 9080
        hostname: 'localhost',
        pool_size: 5,
        max_overflow: 1,
        ssl: true,
        cacertfile: '/path/to/MyRootCA.pem'

  ## With TLS client authentication

      config :ex_dgraph, ExDgraph,
        # default port considered to be: 9080
        hostname: 'localhost',
        pool_size: 5,
        max_overflow: 1,
        ssl: true,
        cacertfile: '/path/to/MyRootCA.pem',
        certfile: '/path/to/MyClient1.pem',
        keyfile: '/path/to/MyClient1.key',

  ## Example

      iex> opts = Application.get_env(:ex_dgraph, ExDgraph)
      {:ok, pid} = ExDgraph.start_link(opts)
  """
  @spec start_link(Keyword.t()) :: Supervisor.on_start()
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  def init(opts) do
    cnf = Utils.default_config(opts)

    children = [
      {ExDgraph.ConfigAgent, cnf},
      DBConnection.child_spec(ExDgraph.Protocol, pool_config(cnf))
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Returns a pool name which can be used to acquire a connection.
  """
  def conn, do: pool_name()

  @doc """
  Returns an environment specific ExDgraph configuration.
  """
  def config, do: ConfigAgent.get_config()

  @doc false
  def config(key), do: Keyword.get(config(), key)

  @doc false
  def config(key, default) do
    Keyword.get(config(), key, default)
  rescue
    _ -> default
  end

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
  @spec query(conn, String.t()) :: {:ok, ExDgraph.Response} | {:error, ExDgraph.Error}
  defdelegate query(conn, statement), to: Query

  @doc """
  The same as `query/2` but raises a ExDgraph.Exception if it fails.
  Returns the server response otherwise.
  """
  @spec query!(conn, String.t()) :: ExDgraph.Response | ExDgraph.Exception
  defdelegate query!(conn, statement), to: Query

  ## Mutation
  ######################

  @doc """
  Sends the mutation to the server and returns `{:ok, result}` or
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

      iex> ExDgraph.mutation(conn, starwars_creation_mutation)
      %{:ok,
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
  @spec mutation(conn, String.t()) :: {:ok, ExDgraph.Response} | {:error, ExDgraph.Error}
  defdelegate mutation(conn, statement), to: Mutation

  @doc """
  The same as `mutation/2` but raises an `ExDgraph.Exception` if it fails.
  Returns the server response otherwise.
  """
  @spec mutation!(conn, String.t()) :: ExDgraph.Response | ExDgraph.Exception
  defdelegate mutation!(conn, statement), to: Mutation

  @doc """
  Allow you to pass a map to insert into the database. The function sends the mutation to the server and returns `{:ok, result}` or `{:error, error}` otherwise. Internally it uses Dgraphs `set_json`.
  The `result` is a map of all values you have passed in but with the field `uid` populated from the database.

  ## Examples

  ```elixir
  map = %{
     name: "Alice",
     friends: %{
       name: "Betty"
     }
   }
   ```

      iex> ExDgraph.set_map(conn, map)
      %{:ok,
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
      }
  """
  @spec set_map(conn, Map.t()) :: {:ok, ExDgraph.Response} | {:error, ExDgraph.Error}
  defdelegate set_map(conn, map), to: Mutation

  @doc """
  The same as `set_map/2` but raises an `ExDgraph.Exception` if it fails.
  Returns the server response otherwise.
  """
  @spec set_map!(conn, Map.t()) :: {:ok, ExDgraph.Response} | {:error, ExDgraph.Error}
  defdelegate set_map!(conn, map), to: Mutation

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
  @spec operation(conn, String.t()) :: {:ok, ExDgraph.Response} | {:error, ExDgraph.Error}
  defdelegate operation(conn, statement), to: Operation

  @doc """
  The same as `operation/2` but raises an `ExDgraph.Exception` if it fails.
  Returns the server response otherwise.
  """
  @spec operation!(conn, String.t()) :: ExDgraph.Response | ExDgraph.Exception
  defdelegate operation!(conn, statement), to: Operation

  ## Helpers
  ######################

  defp pool_config(cnf) do
    [
      name: {:local, pool_name()},
      pool: Keyword.get(cnf, :pool),
      pool_size: Keyword.get(cnf, :pool_size),
      pool_overflow: Keyword.get(cnf, :max_overflow)
    ]
  end
end
