defmodule ExDgraph.Exception do
  @moduledoc """
  This module defines a `ExDgraph.Exception` containing two fields:

  * `code` - the error code
  * `message` - the error details
  """
  @type t :: %ExDgraph.Exception{}

  defexception [:code, :message]
end
