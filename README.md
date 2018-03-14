# ExDgraph [![Build Status](https://travis-ci.org/ospaarmann/exdgraph.svg?branch=master)](https://travis-ci.org/ospaarmann/exdgraph) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Coverage Status](https://coveralls.io/repos/github/ospaarmann/exdgraph/badge.svg?branch=master&refresh=1)](https://coveralls.io/github/ospaarmann/exdgraph?branch=master)

**This is work in progress and not functional as of now. If you want to help, please drop me a message. Any help is greatly appreciated!**

ExDgraph is a gRPC based client for the [Dgraph](https://github.com/dgraph-io/dgraph) database. It uses the [DBConnection](https://hexdocs.pm/db_connection/DBConnection.html) behaviour to support transactions and connection pooling via [Poolboy](https://github.com/devinus/poolboy). Works with Dgraph v1.0.4 (latest).

WORK IN PROGRESS.

> Dgraph is an open source, horizontally scalable and distributed graph database, providing ACID transactions, consistent replication and linearizable reads. [...] Dgraph's goal is to provide Google production level scale and throughput, with low enough latency to be serving real time user queries, over terabytes of structured data. ([Source](https://github.com/dgraph-io/dgraph))

If you want to learn more about Dgraph watch [this talk](https://www.youtube.com/watch?v=cHXbYLNa0qQ).

## Contribute

This is under development and contributions are very welcome. Please add a comment under [this issue](https://github.com/ospaarmann/exdgraph/issues/4) to discuss how to help. Please also read the roadmap at the bottom of this Readme to see where I stand and what the next steps are.

A good start would be to improve test coverage. Run `mix coveralls` to see where work is needed.

## Design principles

- Performance and stability first
- Work as closely to GraphQL+ as possible
- Keep it simple and allow a maximum of flexibility for the user while providing enough syntactic sugar to make it simple to use. Also for people new to Dgraph

## Installation

Add the package `ex_dgraph` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_dgraph, "~> 0.1.0", github: "ospaarmann/exdgraph", branch: "master"}
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

**Usage with Phoenix**

Add the configuration to your respective configuration file:

```elixir
config :ex_dgraph, ExDgraph,
  hostname: 'localhost',
  port: 9080,
  pool_size: 5,
  max_overflow: 1
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

**Example for a query**

```elixir
query = """
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
"""

conn = ExDgraph.conn()
{:ok, msg} = ExDgraph.query(conn, query)
```

**Examples for a mutation**

```elixir

starwars_schema = "id: string @index(exact).
    name: string @index(exact, term) @count .
    age: int @index(int) .
    friend: uid @count .
    dob: dateTime ."

starwars_creation_mutation = """
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
"""

conn = ExDgraph.conn()
{:ok, operation_msg} = ExDgraph.operation(conn, %{schema: starwars_schema})
{:ok, mutation_msg} = ExDgraph.mutation(conn, starwars_creation_mutation)

```

**Examples for an operation**

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

**Example for a raw query**

```elixir
# Connect to Server
{:ok, channel} = GRPC.Stub.connect("#localhost:9080")

# Define query (for now just a string)
query = """
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
"""

# Build request
request = ExDgraph.Api.Request.new(query: query)

# Send request to server
{:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)

# Parse result
json = Poison.decode!(msg.json)
```

## Using with Phoenix 1.3
Since grpc-elixir needs Cowboy 2 you need to upgrade your Phoenix app to work with Cowboy 2.

**Update dependencies in your mix.exs**

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

**Create a self-signed certificate for https**

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

## Running tests
You need Dgraph running locally on port `9080`. A quick way of running any version of Dgraph, is via Docker:

```
$ git clone git@github.com:ospaarmann/exdgraph.git
$ cd exdgraph
$ docker-compose up
$ mix test
```

[More info on how to run Dgraph locally.](https://docs.dgraph.io/get-started/)

## Roadmap

- [X] Connect to Dgraph server via gRPC
- [X] Implement DBConnection behaviour
- [X] Improve test coverage
- [ ] Add documenation
- [X] Improve error handling
- [ ] Implement TLS / authentication
- [ ] Improve request model via specific module
- [ ] Improve response model via specific module
- [X] Query builder
- [X] Query executer
- [X] Mutations
- [X] Operations
- [ ] More intelligent query builder for nested queries

## Notes

- Read more on Dgraph here: https://docs.dgraph.io
- Read more on gRPC here: https://grpc.io/docs/
- Read more on Google Protobuf here: https://developers.google.com/protocol-buffers/
- Read more on DBConnection here: https://hexdocs.pm/db_connection/DBConnection.html

I am using [tony612/grpc-elixir](https://github.com/tony612/grpc-elixir) as Elixir gRPC implementation and [tony612/protobuf-elixir](https://github.com/tony612/protobuf-elixir) as pure Elixir implementation of [Google Protobuf](https://developers.google.com/protocol-buffers/).

## License

Copyright © 2018 Ole Spaarmann <os@ospaarmann.com>

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
