defmodule ExDgraph.Error do
  @moduledoc """
  Dgraph or connection error are wrapped in ExDgraph.Error.
  """
  defexception [:reason, :action, :code]

  @type t :: %ExDgraph.Error{}

  @impl true
  def message(%{action: action, reason: reason}) do
    "#{action} failed with #{inspect(reason)}"
  end
end

