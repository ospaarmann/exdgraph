# ExDgraph [![Build Status](https://travis-ci.org/ospaarmann/exdgraph.svg?branch=master)](https://travis-ci.org/ospaarmann/exdgraph) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**This is work in progress and not functional as of now. If you want to help, please drop me a message. Any help is greatly appreciated!**

ExDgraph is the attempt to create a gRPC based client for the Dgraph database. WORK IN PROGRESS.

- Read more on Dgraph here: https://docs.dgraph.io
- Read more on gRPC here: https://grpc.io/docs/
- Read more on Google Protobuf here: https://developers.google.com/protocol-buffers/

I am using [tony612/grpc-elixir](https://github.com/tony612/grpc-elixir) as Elixir gRPC implementation and [tony612/protobuf-elixir](https://github.com/tony612/protobuf-elixir) as pure Elixir implementation of [Google Protobuf](https://developers.google.com/protocol-buffers/).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exdgraph` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exdgraph, "~> 0.1.0", github: "ospaarmann/exdgraph", branch: "master"}
  ]
end
```

## Usage

Again, this is work in progress. I'll add more examples on how to use this on the go. So far you can connect to a server and run a simple query. I recommend installing and running Dgraph locally with Docker. You find information on how to do that [here](https://docs.dgraph.io/get-started/#from-docker-image). To use this simple example you first have to [import the example data](https://docs.dgraph.io/get-started/#step-3-run-queries). You can just open [http://localhost:8000](http://localhost:8000) in your browser when Dgraph is running to execute and visualize queries using Ratel.

### Simple example

Install ExDgraph and run an interactive console with `iex -S mix`.

```elixir
# Connect to Server
{:ok, channel} = GRPC.Stub.connect("localhost:9080")

# Define query (for now just a string)
query = """
  {
    starwars(func: anyofterms(name, "Star Wars"))
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
Poison.decode!(msg.json)
```

## Roadmap

- [X] Connect to Dgraph server via gRPC
- [ ] Let GenServer handle connection and queries
- [ ] Model request
- [ ] Model response
- [ ] Query builder
- [ ] Query executer
- [ ] Mutation builder
- [ ] Mutation executer
- [ ] Operation builder (for Alter)
- [ ] Operation executer
- [ ] Poolboy for connection pooling
- [ ] More intelligent query builder for nested queries
