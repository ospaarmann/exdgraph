
# Gremlin graph support

In this case, only elixir functions which simulate gremlin.

## Gremlin Steps

### AddVertex Step
The `addV`-step is used to add vertices to the graph ([addV step](http://tinkerpop.apache.org/docs/current/reference/#addvertex-step))

  
The following Gremlin statement inserts a "toon" vertex into the graph
```
gremlin> g.addV('toon')
==>v[13]
```

And now with **Elixir**.
```elixir
{:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
{:ok, graph} = Graph.new(channel)

graph
|> addV(Toon)
```
The first lines create the `Graph` and connect it to `dgraph`. These are not listed in all samples.

### AddProperty Step
The `property`-step is used to add properties to the elements of the graph. ([property step](http://tinkerpop.apache.org/docs/current/reference/#addproperty-step))

The following Gremlin statement inserts the "*Bugs Bunny*" vertex into the graph
```
gremlin> g.addV('toon').property('name','Bugs Bunny').property('type','Toon')
==>v[13]
```

And now with **Elixir**.
```elixir
{:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
{:ok, graph} = Graph.new(channel)

graph
|> addV(Toon)
|> property("name", "Bugs Bunny")
|> property("type", "Toon")
```

### AddEdge Step
The `addE`-step is used to add an edge between two vertices  ([addE step](http://tinkerpop.apache.org/docs/current/reference/#addedge-step)) 


```elixir
marko =
    graph
    |> addV(Person)
    |> property("name", "Makro")

peter =
    graph
    |> addV(Person)
    |> property("name", "Peter")

# gremlin> g.addE('knows').from(marko).to(peter)
graph
|> addE("knows")
|> from(marko)
|> to(peter)
```

###  V Step


```elixir
edwin =
    graph
    |> addV(Person)
    |> property("name", "Edwin")
# Get a vertex with the unique identifier.
vertex =
    graph
    |> v(edwin.uid)
```


