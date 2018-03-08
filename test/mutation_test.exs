defmodule MutationTest do
  @moduledoc """
  """
  use ExUnit.Case
  require Logger
  alias ExDgraph.Api.Operation

  alias ExDgraph.Utils

  @testing_schema "id: string @index(exact).
      name: string @index(exact, term) @count .
      age: int @index(int) .
      friend: uid @count .
      dob: dateTime ."

  setup_all do
    cnf = Utils.default_config()
    # TODO: It fails right at the connect on TravisCi
    {:ok, channel} = GRPC.Stub.connect("#{cnf[:hostname]}:#{cnf[:port]}")
    operation = Operation.new(drop_all: true)
    {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)
    operation = Operation.new(schema: @testing_schema)
    {:ok, _} = channel |> ExDgraph.Api.Dgraph.Stub.alter(operation)

    on_exit(fn ->
      # close channel ?
      :ok
    end)
  end

  test "Runs a mutation" do
    # Get connection
    conn = ExDgraph.conn()

    # Define query (for now just a string)
    mutation = """
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
    {:ok, mutation_msg} = ExDgraph.mutation(conn, mutation)

    assert mutation_msg.context.aborted == false
  end
end
