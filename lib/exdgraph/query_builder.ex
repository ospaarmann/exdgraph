defmodule ExDgraph.GraphQL do
  @moduledoc """
  """
  require Logger

  alias ExDgraph.GraphQL

  @enforce_keys [:conn]
  @doc """
  The graph properties.
  """
  defstruct conn: DBConnection,
            name: String,
            query: String,
            query_root: nil,
            filter_root: nil,
            pagination_root: nil,
            body: nil,
            current_predicate: nil,
            current_pagination: nil

  # TODO: @spec
  # TODO: @doc

  @doc """
  Creates a new graph
  # graph_query
  """
  def new(conn, name \\ "graphql") do
    {:ok, %GraphQL{conn: conn, name: name}}
  end

  # @spec query(GraphQL) :: GraphQL
  def root(graph_in, matching_type, predicate_object) do
    case graph_in do
      {:ok, graph} ->
        query_root = {matching_type, predicate_object}
        {:ok, %GraphQL{graph | query_root: query_root}}

      {:error, error} ->
        {:error, error}
    end
  end

  def query_root(graph) do
    if graph.query_root != nil do
      IO.inspect(graph.query_root)
      predicate_object = elem(graph.query_root, 1)

      if is_tuple(predicate_object) do
        predicate = elem(predicate_object, 0)
        object = elem(predicate_object, 1)
        "func: #{elem(graph.query_root, 0)}(#{predicate}, \"#{object}\") #{graph.pagination_root}"
      else
        "func: #{elem(graph.query_root, 0)}(#{predicate_object}) #{graph.pagination_root}"
      end
    else
      ""
    end
  end

  @doc """
  If current_predicate == nil, then the pagination is set to  the roo.
   first: N , offset: N , after: UID
  """
  defp pagination(graph_in, pagination) do
    case graph_in do
      {:ok, graph} ->
        if graph.current_predicate == nil do
          pagination_root = ", #{elem(pagination, 0)} #{elem(pagination, 1)}"
          {:ok, %GraphQL{graph | pagination_root: pagination_root}}
        else
          # predicate pagination
          graph_in
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def first(graph_in, n) do
    pagination(graph_in, {"first:", n})
  end

  def filter_root(graph) do
    ""
  end

  def query_body(graph) do
    "name"

    if graph.body != nil do
      ""
    else
      # default name, expand(_all_) or empty ? 
      "expand(_all_)"
    end
  end

  @spec request(GraphQL) :: GraphQL
  def request(graph_in) do
    case graph_in do
      {:ok, graph} ->
        # <> "\n\t}"
        query =
          "\n{ #{graph.name}(#{GraphQL.query_root(graph)}) #{GraphQL.filter_root(graph)} \n\t{\n" <>
            "\t\t" <> "#{GraphQL.query_body(graph)}" <> "\n\t}" <> "\n}"

        %GraphQL{graph | query: query}
        result = ExDgraph.Query.query(graph.conn, query)

        case result do
          {:ok, query_msg} ->
            res = query_msg.result[String.to_atom(graph.name)]
            {:ok, res}

          {:error, error} ->
            Logger.error(fn -> "💡 Error: #{inspect(error)}" end)
            {:error, error}
        end

      {:error, error} ->
        Logger.error(fn -> "💡 Error: #{inspect(error)}" end)
        {:error, error}
    end
  end
end
