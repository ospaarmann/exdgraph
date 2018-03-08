# Logger.configure(level: :info)
ExUnit.start(exclude: [:skip])

defmodule ExDgraph.TestHelper do
  @starwars_schema "id: string @index(exact).
      name: string @index(exact, term) @count .
      age: int @index(int) .
      friend: uid @count .
      dob: dateTime ."

  @starwars_creation_mutation """
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

  def import_starwars_sample() do
    conn = ExDgraph.conn()
    ExDgraph.operation(conn, %{schema: @starwars_schema})
    {:ok, _} = ExDgraph.mutation(conn, @starwars_creation_mutation)
  end

  def starwars_creation_mutation() do
    @starwars_creation_mutation
  end

  def drop_all() do
    conn = ExDgraph.conn()
    ExDgraph.operation(conn, %{drop_all: true})
  end
end

if Process.whereis(ExDgraph.pool_name()) == nil do
  {:ok, _pid} = ExDgraph.start_link(Application.get_env(:ex_dgraph, ExDgraph))
end

Process.flag(:trap_exit, true)
