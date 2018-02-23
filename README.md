# ExDgraph

**This is work in progress and not functional as of now. If you want to help, please drop me a message. Any help is greatly appreciated!**

ExDgraph is the attempt to create a gRPC based client for the Dgraph database.

- Read more on Dgraph here: https://docs.dgraph.io
- Read more on gRPC here: https://grpc.io/docs/
- Read more on Google Protobuf here: https://developers.google.com/protocol-buffers/

I am using [tony612/grpc-elixir](https://github.com/tony612/grpc-elixir) as Elixir gRPC implementation and [tony612/protobuf-elixir](https://github.com/tony612/protobuf-elixir) as pure Elixir implementation of [Google Protobuf](https://developers.google.com/protocol-buffers/).

## Roadmap

[ ] Connect to Dgraph server via gRPC
[ ] Model request
[ ] Model response
[ ] Query builder
[ ] Query executer
[ ] Mutation builder
[ ] Mutation executer
[ ] Operation builder (for Alter)
[ ] Opation executer
[ ] More intelligent query builder for nested queries

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exdgraph` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exdgraph, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/exdgraph](https://hexdocs.pm/exdgraph).
