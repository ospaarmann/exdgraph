defmodule ExDgraph.Error do
  @moduledoc """
  Dgraph or connection error are wrapped in ExDgraph.Error.
  """

  @type t :: %ExDgraph.Error{
          reason: String.t(),
          action: atom(),
          code: non_neg_integer
        }

  defexception [:reason, :action, :code]

  @impl true
  def message(%{action: action, reason: reason}) do
    "#{action} failed with #{inspect(reason)}"
  end
end

defmodule ExDgraph.QueryResult do
  @moduledoc """
  Results from a query are wrapped in ExDgraph.QueryResult
  """

  @type t :: %__MODULE__{
          data: %{optional(any) => any},
          schema: [any()],
          txn: %ExDgraph.Api.TxnContext{},
          uids: map() | nil
        }

  defstruct [:data, :schema, :txn, :uids]
end

defmodule ExDgraph.MutationResult do
  @moduledoc """
  Results from a mutation are wrapped in ExDgraph.MutationResult
  """

  alias ExDgraph.Api

  @type t :: %__MODULE__{
          data: %{optional(any) => any},
          uids: %{String.t() => String.t()},
          context: Api.TxnContext.t() | nil,
          latency: Api.Latency.t() | nil
        }

  defstruct [:data, :uids, :context, :latency]
end

defmodule ExDgraph.Payload do
  @moduledoc """
  Results from alter are wrapped in ExDgraph.Payload
  """

  @type t :: %__MODULE__{
          data: %{optional(any) => any}
        }

  defstruct [:data]
end
