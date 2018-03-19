defmodule ExDgraph.Expr.Uid do
  @moduledoc """
  https://docs.dgraph.io/query-language/#uid

  Syntax Examples:

    q(func: uid(<uid>))
    predicate @filter(uid(<uid1>, ..., <uidn>))
    predicate @filter(uid(a)) for variable a
    q(func: uid(a,b)) for variables a and b

  """
  alias ExDgraph.Expr.Uid
  alias ExDgraph.Utils


  defstruct [
    :value,
    :type,
  ]

  defmacro __using__(_) do
    quote do
      def uid(value) do
        ExDgraph.Expr.Uid.new(value)
      end
    end
  end

  @types [
    :literal,
    :expression,
  ]

  def new(value) when is_binary(value) do
    new(value, :literal)
  end
  def new(value) when is_atom(value) do
    new(value, :expression)
  end
  def new(uids) when is_list(uids) do
    # lists of uid literals are rendered inside a `uid(<uids_here>)` function (as in @filter)
    # lists of uid variables are rendered inside a `uid(<uids_here>)` function (as in @filter)
    # therefore any list is an uid expression
    new(uids, :expression)
  end

  def new(value, type) when (is_atom(value) or is_binary(value) or is_list(value)) and type in @types do
    %Uid{
      value: value,
      type: type,
    }
  end

  @doc """
  This function is used by Func to ensure that a uid string ("0x9") is rendered
  as an expression literal `uid(0x9)` instead of an actual literal `<0x9>`
  """
  def as_expression(%Uid{} = u) do
    %{ u | type: :expression }
  end

  def as_literal(%Uid{} = u) do
    %{ u | type: :literal }
  end

  def as_naked(%Uid{} = u) do
    %{ u | type: :naked}
  end

  def render(%Uid{value: value}) when is_atom(value) do
    render_expression([value])
  end
  def render(%Uid{value: value, type: :literal}) when is_binary(value) do
    {:ok, uid_literal} = Utils.as_literal(value, :uid)
    uid_literal
  end
  def render(%Uid{value: value, type: :naked}) when is_binary(value) do
    value
  end
  def render(%Uid{value: value, type: :expression}) when (is_atom(value) or is_binary(value)) do
    render_expression([value])
  end
  def render(%Uid{value: value, type: :expression}) when is_list(value) do
    render_expression(value)
  end

  defp render_expression(uids) when is_list(uids) do
    args =
      uids
      |> Enum.map(&to_string/1)
      |> Enum.join(", ")
    "uid("<>args<>")"
  end

end

defimpl String.Chars, for: ExDgraph.Expr.Uid do

  def to_string(uid) do
    ExDgraph.Expr.Uid.render(uid)
  end

end

# Source https://github.com/elbow-jason/dgraph_ex
# Copyright (c) 2017 Jason Goldberger
