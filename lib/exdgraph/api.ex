defmodule ExDgraph.Api.Request do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          query: String.t(),
          vars: %{String.t() => String.t()},
          start_ts: non_neg_integer,
          lin_read: ExDgraph.Api.LinRead.t()
        }
  defstruct [:query, :vars, :start_ts, :lin_read]

  field(:query, 1, type: :string)
  field(:vars, 2, repeated: true, type: ExDgraph.Api.Request.VarsEntry, map: true)
  field(:start_ts, 13, type: :uint64)
  field(:lin_read, 14, type: ExDgraph.Api.LinRead)
end

defmodule ExDgraph.Api.Request.VarsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule ExDgraph.Api.Response do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          json: String.t(),
          schema: [ExDgraph.Api.SchemaNode.t()],
          txn: ExDgraph.Api.TxnContext.t(),
          latency: ExDgraph.Api.Latency.t()
        }
  defstruct [:json, :schema, :txn, :latency]

  field(:json, 1, type: :bytes)
  field(:schema, 2, repeated: true, type: ExDgraph.Api.SchemaNode)
  field(:txn, 3, type: ExDgraph.Api.TxnContext)
  field(:latency, 12, type: ExDgraph.Api.Latency)
end

defmodule ExDgraph.Api.Assigned do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          uids: %{String.t() => String.t()},
          context: ExDgraph.Api.TxnContext.t()
        }
  defstruct [:uids, :context]

  field(:uids, 1, repeated: true, type: ExDgraph.Api.Assigned.UidsEntry, map: true)
  field(:context, 2, type: ExDgraph.Api.TxnContext)
end

defmodule ExDgraph.Api.Assigned.UidsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t()
        }
  defstruct [:key, :value]

  field(:key, 1, type: :string)
  field(:value, 2, type: :string)
end

defmodule ExDgraph.Api.Mutation do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          set_json: String.t(),
          delete_json: String.t(),
          set_nquads: String.t(),
          del_nquads: String.t(),
          set: [ExDgraph.Api.NQuad.t()],
          del: [ExDgraph.Api.NQuad.t()],
          start_ts: non_neg_integer,
          commit_now: boolean,
          ignore_index_conflict: boolean
        }
  defstruct [
    :set_json,
    :delete_json,
    :set_nquads,
    :del_nquads,
    :set,
    :del,
    :start_ts,
    :commit_now,
    :ignore_index_conflict
  ]

  field(:set_json, 1, type: :bytes)
  field(:delete_json, 2, type: :bytes)
  field(:set_nquads, 3, type: :bytes)
  field(:del_nquads, 4, type: :bytes)
  field(:set, 10, repeated: true, type: ExDgraph.Api.NQuad)
  field(:del, 11, repeated: true, type: ExDgraph.Api.NQuad)
  field(:start_ts, 13, type: :uint64)
  field(:commit_now, 14, type: :bool)
  field(:ignore_index_conflict, 15, type: :bool)
end

defmodule ExDgraph.Api.AssignedIds do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          startId: non_neg_integer,
          endId: non_neg_integer
        }
  defstruct [:startId, :endId]

  field(:startId, 1, type: :uint64)
  field(:endId, 2, type: :uint64)
end

defmodule ExDgraph.Api.Operation do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          schema: String.t(),
          drop_attr: String.t(),
          drop_all: boolean
        }
  defstruct [:schema, :drop_attr, :drop_all]

  field(:schema, 1, type: :string)
  field(:drop_attr, 2, type: :string)
  field(:drop_all, 3, type: :bool)
end

defmodule ExDgraph.Api.Payload do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          Data: String.t()
        }
  defstruct [:Data]

  field(:Data, 1, type: :bytes)
end

defmodule ExDgraph.Api.TxnContext do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          start_ts: non_neg_integer,
          commit_ts: non_neg_integer,
          aborted: boolean,
          keys: [String.t()],
          lin_read: ExDgraph.Api.LinRead.t()
        }
  defstruct [:start_ts, :commit_ts, :aborted, :keys, :lin_read]

  field(:start_ts, 1, type: :uint64)
  field(:commit_ts, 2, type: :uint64)
  field(:aborted, 3, type: :bool)
  field(:keys, 4, repeated: true, type: :string)
  field(:lin_read, 13, type: ExDgraph.Api.LinRead)
end

defmodule ExDgraph.Api.Check do
  @moduledoc false
  use Protobuf, syntax: :proto3

  defstruct []
end

defmodule ExDgraph.Api.Version do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          tag: String.t()
        }
  defstruct [:tag]

  field(:tag, 1, type: :string)
end

defmodule ExDgraph.Api.LinRead do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          ids: %{non_neg_integer => non_neg_integer}
        }
  defstruct [:ids]

  field(:ids, 1, repeated: true, type: ExDgraph.Api.LinRead.IdsEntry, map: true)
end

defmodule ExDgraph.Api.LinRead.IdsEntry do
  @moduledoc false
  use Protobuf, map: true, syntax: :proto3

  @type t :: %__MODULE__{
          key: non_neg_integer,
          value: non_neg_integer
        }
  defstruct [:key, :value]

  field(:key, 1, type: :uint32)
  field(:value, 2, type: :uint64)
end

defmodule ExDgraph.Api.Latency do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          parsing_ns: non_neg_integer,
          processing_ns: non_neg_integer,
          encoding_ns: non_neg_integer
        }
  defstruct [:parsing_ns, :processing_ns, :encoding_ns]

  field(:parsing_ns, 1, type: :uint64)
  field(:processing_ns, 2, type: :uint64)
  field(:encoding_ns, 3, type: :uint64)
end

defmodule ExDgraph.Api.NQuad do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          subject: String.t(),
          predicate: String.t(),
          object_id: String.t(),
          object_value: ExDgraph.Api.Value.t(),
          label: String.t(),
          lang: String.t(),
          facets: [ExDgraph.Api.Facet.t()]
        }
  defstruct [:subject, :predicate, :object_id, :object_value, :label, :lang, :facets]

  field(:subject, 1, type: :string)
  field(:predicate, 2, type: :string)
  field(:object_id, 3, type: :string)
  field(:object_value, 4, type: ExDgraph.Api.Value)
  field(:label, 5, type: :string)
  field(:lang, 6, type: :string)
  field(:facets, 7, repeated: true, type: ExDgraph.Api.Facet)
end

defmodule ExDgraph.Api.Value do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          val: {atom, any}
        }
  defstruct [:val]

  oneof(:val, 0)
  field(:default_val, 1, type: :string, oneof: 0)
  field(:bytes_val, 2, type: :bytes, oneof: 0)
  field(:int_val, 3, type: :int64, oneof: 0)
  field(:bool_val, 4, type: :bool, oneof: 0)
  field(:str_val, 5, type: :string, oneof: 0)
  field(:double_val, 6, type: :double, oneof: 0)
  field(:geo_val, 7, type: :bytes, oneof: 0)
  field(:date_val, 8, type: :bytes, oneof: 0)
  field(:datetime_val, 9, type: :bytes, oneof: 0)
  field(:password_val, 10, type: :string, oneof: 0)
  field(:uid_val, 11, type: :uint64, oneof: 0)
end

defmodule ExDgraph.Api.Facet do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t(),
          val_type: integer,
          tokens: [String.t()],
          alias: String.t()
        }
  defstruct [:key, :value, :val_type, :tokens, :alias]

  field(:key, 1, type: :string)
  field(:value, 2, type: :bytes)
  field(:val_type, 3, type: ExDgraph.Api.Facet.ValType, enum: true)
  field(:tokens, 4, repeated: true, type: :string)
  field(:alias, 5, type: :string)
end

defmodule ExDgraph.Api.Facet.ValType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field(:STRING, 0)
  field(:INT, 1)
  field(:FLOAT, 2)
  field(:BOOL, 3)
  field(:DATETIME, 4)
end

defmodule ExDgraph.Api.SchemaNode do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          predicate: String.t(),
          type: String.t(),
          index: boolean,
          tokenizer: [String.t()],
          reverse: boolean,
          count: boolean,
          list: boolean
        }
  defstruct [:predicate, :type, :index, :tokenizer, :reverse, :count, :list]

  field(:predicate, 1, type: :string)
  field(:type, 2, type: :string)
  field(:index, 3, type: :bool)
  field(:tokenizer, 4, repeated: true, type: :string)
  field(:reverse, 5, type: :bool)
  field(:count, 6, type: :bool)
  field(:list, 7, type: :bool)
end

defmodule ExDgraph.Api.Dgraph.Service do
  @moduledoc false
  use GRPC.Service, name: "api.Dgraph"

  rpc(:Query, ExDgraph.Api.Request, ExDgraph.Api.Response)
  rpc(:Mutate, ExDgraph.Api.Mutation, ExDgraph.Api.Assigned)
  rpc(:Alter, ExDgraph.Api.Operation, ExDgraph.Api.Payload)
  rpc(:CommitOrAbort, ExDgraph.Api.TxnContext, ExDgraph.Api.TxnContext)
  rpc(:CheckVersion, ExDgraph.Api.Check, ExDgraph.Api.Version)
end

defmodule ExDgraph.Api.Dgraph.Stub do
  @moduledoc false
  use GRPC.Stub, service: ExDgraph.Api.Dgraph.Service
end
