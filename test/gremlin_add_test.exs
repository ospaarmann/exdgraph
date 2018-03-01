defmodule GremlinAddTest do
    @moduledoc """
    """
    use ExUnit.Case
 
    import Gremlin
    
  
    require Logger
  
    # TODO: setup_all()
    
    test "mutate" do
      # Port: 9080 or 9082
      {:ok, channel} = GRPC.Stub.connect("localhost:9082")
      # Define query (for now just a string)
      m = """
       _:class <student> _:x .
             _:class <student> _:y .
             _:class <name> "awesome class" .
             _:x <name> "Alice" .
             _:x <planet> "Mars" .
             _:x <friend> _:y .
             _:y <name> "Bob" .
      """
      # Build request
      request = ExDgraph.Api.Mutation.new(set_nquads: m, commit_now: true)
      # Send request to server
      {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.mutate(request)
    end

    test "Gremlin AddVertex Step ; AddProperty Step" do
      {:ok, graph} = Graph.new
        graph
          |> addV(Toon)
          |> property("name", "Bugs Bunny")
          |> property("type", "Toon")

      # TODO: Helper func
      # Connect to Server
      {:ok, channel} = GRPC.Stub.connect("localhost:9082")
      query = """
        {
          toons(func: anyofterms(name, "Bugs Bunny"))
          {
            uid
            name
            type
          }
        }
      """
      request = ExDgraph.Api.Request.new(query: query)
      {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)
      json = Poison.decode!(msg.json)
      toons = json["toons"]
      toon_one = List.first(toons)
      assert "Bugs Bunny" == toon_one["name"]
      assert "Toon" == toon_one["type"]  
    end
  
  end
  