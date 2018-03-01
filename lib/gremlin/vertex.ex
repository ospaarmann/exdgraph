defmodule Vertex do
    @moduledoc """
    The vertex for gremlin

    Copyright © 2018 Edwin Buehler. All rights reserved.
    """
    require Logger

    @doc """
    The vertex properties.
    Reserved for cache and other
    """    
    defstruct uid: String,
        vertex_struct: Struct

    @doc """
    Creates a new graph
    """
    def new(the_uid, the_struct) do
        %Vertex{uid: the_uid, vertex_struct: the_struct}
    end
end