defmodule ExDgraph.ConfigAgent do
  @moduledoc """
  Just hold the user config and offer some utility for accessing it
  """

  use Agent

  @doc false
  def start_link(opts) do
    Agent.start_link(fn -> %{opts: opts} end, name: __MODULE__)
  end

  @doc false
  def get_config do
    Agent.get(__MODULE__, fn state -> state[:opts] end)
  end
end
