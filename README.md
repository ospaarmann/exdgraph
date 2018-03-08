# ExDgraph [![Build Status](https://travis-ci.org/ospaarmann/exdgraph.svg?branch=master)](https://travis-ci.org/ospaarmann/exdgraph) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Coverage Status](https://coveralls.io/repos/github/ospaarmann/exdgraph/badge.svg?branch=master)](https://coveralls.io/github/ospaarmann/exdgraph?branch=master)

**This is work in progress and not functional as of now. If you want to help, please drop me a message. Any help is greatly appreciated!**

ExDgraph is a gRPC based client for the [Dgraph](https://github.com/dgraph-io/dgraph) database. It uses the [DBConnection](https://hexdocs.pm/db_connection/DBConnection.html) behaviour to support transactions and connection pooling via [Poolboy](https://github.com/devinus/poolboy).

WORK IN PROGRESS.

> Dgraph is an open source, horizontally scalable and distributed graph database, providing ACID transactions, consistent replication and linearizable reads. [...] Dgraph's goal is to provide Google production level scale and throughput, with low enough latency to be serving real time user queries, over terabytes of structured data. ([Source](https://github.com/dgraph-io/dgraph))

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

## Usage

Again, this is work in progress. I'll add more examples on how to use this on the go. So far you can connect to a server and run a simple query. I recommend installing and running Dgraph locally with Docker. You find information on how to do that [here](https://docs.dgraph.io/get-started/#from-docker-image). To use this simple example you first have to [import the example data](https://docs.dgraph.io/get-started/#step-3-run-queries). You can just open [http://localhost:8000](http://localhost:8000) in your browser when Dgraph is running to execute and visualize queries using Ratel.

At the moment simple queries, mutations and operations are supported via the DBConnection behaviour. Everything else is done directly via the Protobuf API. This will change. Check the tests for examples.

**Example for a query using DBConnection**

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

## Running tests
You need Dgraph running locally on port 9080. A quick way of running any version of Dgraph, is via docker:

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
- [ ] Improve test coverage
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
