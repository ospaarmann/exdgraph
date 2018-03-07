defmodule SimpleBasicTest do
    @moduledoc """
    """
    use ExUnit.Case
    require Logger
  
    @testing_schema "id: string @index(exact).
      name: string @index(exact, term) @count .
      age: int @index(int) .
      friend: uid @count .
      dob: dateTime ."
  
    setup_all do
      # ! --------------------------
      # ! Wait until dgraph is ready
      # ! --------------------------
      Process.sleep(2000)
      #Logger.info fn -> "💡 GRPC-Server: #{Application.get_env(:exdgraph, :dgraphServerGRPC)}" end
      {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
      operation = ExDgraph.Api.Operation.new(drop_all: true)
      {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
      operation = ExDgraph.Api.Operation.new(schema: @testing_schema)
      {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
      :ok
    end
  
    test "Create & Query" do
      # Port: 9080 or 9082
      {:ok, channel} = GRPC.Stub.connect(Application.get_env(:exdgraph, :dgraphServerGRPC))
      # Define query (for now just a string)
      m = """
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
  
      # Build request
      request = ExDgraph.Api.Mutation.new(set_nquads: m, commit_now: true)
      # Send request to server
      {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.mutate(request)
  
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
  
      request = ExDgraph.Api.Request.new(query: query)
      {:ok, msg} = channel |> ExDgraph.Api.Dgraph.Stub.query(request)
      json = Poison.decode!(msg.json)
      starwars = json["starwars"]
      one = List.first(starwars)
      assert "Star Wars: Episode VI - Return of the Jedi" == one["name"]
      assert "1983-05-25" == one["release_date"]
    end

  end
  