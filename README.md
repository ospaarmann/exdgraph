# ExDgraph [![Build Status](https://travis-ci.org/ospaarmann/exdgraph.svg?branch=master)](https://travis-ci.org/ospaarmann/exdgraph) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Coverage Status](https://coveralls.io/repos/github/ospaarmann/exdgraph/badge.svg?branch=master&refresh=1)](https://coveralls.io/github/ospaarmann/exdgraph?branch=master)

**ExDgraph is functional but I would be careful using it in production. If you want to help, please drop me a message. Any help is greatly appreciated!**

ExDgraph is a gRPC based client for the [Dgraph](https://github.com/dgraph-io/dgraph) database. It uses the [DBConnection](https://hexdocs.pm/db_connection/DBConnection.html) behaviour to support transactions and connection pooling. Works with Dgraph v1.0.16 (latest).

> Dgraph is an open source, horizontally scalable and distributed graph database, providing ACID transactions, consistent replication and linearizable reads. [...] Dgraph's goal is to provide Google production level scale and throughput, with low enough latency to be serving real time user queries, over terabytes of structured data. ([Source](https://github.com/dgraph-io/dgraph))

If you want to learn more about Dgraph watch [this talk](https://www.youtube.com/watch?v=cHXbYLNa0qQ).

## Questions / need help?

If you have questions on how to use ExDgraph, or if you want to propose new features or talk about an issue please head over to the **#elixir** channel in [Dgraph Slack](https://slack.dgraph.io/).

## Contribute

This is under development and contributions are very welcome. If you want to contribute, please read [our guidelines](https://github.com/ospaarmann/exdgraph/blob/master/CONTRIBUTING.md). Please also read the roadmap at the bottom of this Readme to see where I stand and what the next steps are.

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

**Usage with Phoenix**

Add the configuration to your respective configuration file:

```elixir
config :ex_dgraph, ExDgraph,
  hostname: 'localhost',
  port: 9080,
  pool_size: 5
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

**Example for inserting a map**

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

This is an example on how to use the Protobuf API with GRPC directly and how to extend the library.

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
- [X] Add documentation
- [X] Improve error handling
- [X] Implement TLS / authentication
- [X] Query builder
- [X] Query executer
- [X] Mutations
- [X] Operations
- [ ] Support transactions
- [ ] Per-call GRPC deadline

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
