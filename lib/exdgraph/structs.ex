defmodule ExDgraph.Error do
  @moduledoc """
  Dgraph or connection error are wrapped in ExDgraph.Error.
  """
  defexception [:reason, :action, :code]

  @type t :: %ExDgraph.Error{
          reason: String.t(),
          action: atom(),
          code: non_neg_integer
        }

  @impl true
  def message(%{action: action, reason: reason}) do
    "#{action} failed with #{inspect(reason)}"
  end
end

defmodule ExDgraph.Result do
  @moduledoc """
  Results from a query are wrapped in ExDgraph.Result
  """

  @type t :: %__MODULE__{
          data: %{optional(any) => any},
          schema: [any()],
          txn: %ExDgraph.Api.TxnContext{}
        }

  defstruct [:data, :schema, :txn]
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
