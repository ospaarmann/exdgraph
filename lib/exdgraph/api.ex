alias ExDgraph.Api

defmodule Api.Request do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          query: String.t(),
          vars: %{String.t() => String.t()},
          start_ts: non_neg_integer,
          lin_read: Api.LinRead.t() | nil,
          read_only: boolean,
          best_effort: boolean
        }
  defstruct [:query, :vars, :start_ts, :lin_read, :read_only, :best_effort]

  field(:query, 1, type: :string)
  field(:vars, 2, repeated: true, type: Api.Request.VarsEntry, map: true)
  field(:start_ts, 13, type: :uint64)
  field(:lin_read, 14, type: Api.LinRead)
  field(:read_only, 15, type: :bool)
  field(:best_effort, 16, type: :bool)
end

defmodule Api.Request.VarsEntry do
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

defmodule Api.Response do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          json: binary,
          schema: [Api.SchemaNode.t()],
          txn: Api.TxnContext.t() | nil,
          latency: Api.Latency.t() | nil
        }
  defstruct [:json, :schema, :txn, :latency]

  field(:json, 1, type: :bytes)
  field(:schema, 2, repeated: true, type: Api.SchemaNode, deprecated: true)
  field(:txn, 3, type: Api.TxnContext)
  field(:latency, 12, type: Api.Latency)
end

defmodule Api.Assigned do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          uids: %{String.t() => String.t()},
          context: Api.TxnContext.t() | nil,
          latency: Api.Latency.t() | nil
        }
  defstruct [:uids, :context, :latency]

  field(:uids, 1, repeated: true, type: Api.Assigned.UidsEntry, map: true)
  field(:context, 2, type: Api.TxnContext)
  field(:latency, 12, type: Api.Latency)
end

defmodule Api.Assigned.UidsEntry do
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

defmodule Api.Mutation do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          set_json: binary,
          delete_json: binary,
          set_nquads: binary,
          del_nquads: binary,
          query: String.t(),
          set: [Api.NQuad.t()],
          del: [Api.NQuad.t()],
          start_ts: non_neg_integer,
          commit_now: boolean,
          ignore_index_conflict: boolean
        }
  defstruct [
    :set_json,
    :delete_json,
    :set_nquads,
    :del_nquads,
    :query,
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
  field(:query, 5, type: :string)
  field(:set, 10, repeated: true, type: Api.NQuad)
  field(:del, 11, repeated: true, type: Api.NQuad)
  field(:start_ts, 13, type: :uint64)
  field(:commit_now, 14, type: :bool)
  field(:ignore_index_conflict, 15, type: :bool)
end

defmodule Api.Operation do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          schema: String.t(),
          drop_attr: String.t(),
          drop_all: boolean,
          drop_op: atom | integer,
          drop_value: String.t()
        }
  defstruct [:schema, :drop_attr, :drop_all, :drop_op, :drop_value]

  field(:schema, 1, type: :string)
  field(:drop_attr, 2, type: :string)
  field(:drop_all, 3, type: :bool)
  field(:drop_op, 4, type: Api.Operation.DropOp, enum: true)
  field(:drop_value, 5, type: :string)
end

defmodule Api.Operation.DropOp do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field(:NONE, 0)
  field(:ALL, 1)
  field(:DATA, 2)
  field(:ATTR, 3)
  field(:TYPE, 4)
end

defmodule Api.Payload do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          Data: binary
        }
  defstruct [:Data]

  field(:Data, 1, type: :bytes)
end

defmodule Api.TxnContext do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          start_ts: non_neg_integer,
          commit_ts: non_neg_integer,
          aborted: boolean,
          keys: [String.t()],
          preds: [String.t()],
          lin_read: Api.LinRead.t() | nil
        }
  defstruct [:start_ts, :commit_ts, :aborted, :keys, :preds, :lin_read]

  field(:start_ts, 1, type: :uint64)
  field(:commit_ts, 2, type: :uint64)
  field(:aborted, 3, type: :bool)
  field(:keys, 4, repeated: true, type: :string)
  field(:preds, 5, repeated: true, type: :string)
  field(:lin_read, 13, type: Api.LinRead)
end

defmodule Api.Check do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{}
  defstruct []
end

defmodule Api.Version do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          tag: String.t()
        }
  defstruct [:tag]

  field(:tag, 1, type: :string)
end

defmodule Api.LinRead do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          ids: %{non_neg_integer => non_neg_integer},
          sequencing: atom | integer
        }
  defstruct [:ids, :sequencing]

  field(:ids, 1, repeated: true, type: Api.LinRead.IdsEntry, map: true)
  field(:sequencing, 2, type: Api.LinRead.Sequencing, enum: true)
end

defmodule Api.LinRead.IdsEntry do
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

defmodule Api.LinRead.Sequencing do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field(:CLIENT_SIDE, 0)
  field(:SERVER_SIDE, 1)
end

defmodule Api.Latency do
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

defmodule Api.NQuad do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          subject: String.t(),
          predicate: String.t(),
          object_id: String.t(),
          object_value: Api.Value.t() | nil,
          label: String.t(),
          lang: String.t(),
          facets: [Api.Facet.t()]
        }
  defstruct [:subject, :predicate, :object_id, :object_value, :label, :lang, :facets]

  field(:subject, 1, type: :string)
  field(:predicate, 2, type: :string)
  field(:object_id, 3, type: :string)
  field(:object_value, 4, type: Api.Value)
  field(:label, 5, type: :string)
  field(:lang, 6, type: :string)
  field(:facets, 7, repeated: true, type: Api.Facet)
end

defmodule Api.Value do
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

defmodule Api.Facet do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          key: String.t(),
          value: binary,
          val_type: atom | integer,
          tokens: [String.t()],
          alias: String.t()
        }
  defstruct [:key, :value, :val_type, :tokens, :alias]

  field(:key, 1, type: :string)
  field(:value, 2, type: :bytes)
  field(:val_type, 3, type: Api.Facet.ValType, enum: true)
  field(:tokens, 4, repeated: true, type: :string)
  field(:alias, 5, type: :string)
end

defmodule Api.Facet.ValType do
  @moduledoc false
  use Protobuf, enum: true, syntax: :proto3

  field(:STRING, 0)
  field(:INT, 1)
  field(:FLOAT, 2)
  field(:BOOL, 3)
  field(:DATETIME, 4)
end

defmodule Api.SchemaNode do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          predicate: String.t(),
          type: String.t(),
          index: boolean,
          tokenizer: [String.t()],
          reverse: boolean,
          count: boolean,
          list: boolean,
          upsert: boolean,
          lang: boolean
        }
  defstruct [:predicate, :type, :index, :tokenizer, :reverse, :count, :list, :upsert, :lang]

  field(:predicate, 1, type: :string)
  field(:type, 2, type: :string)
  field(:index, 3, type: :bool)
  field(:tokenizer, 4, repeated: true, type: :string)
  field(:reverse, 5, type: :bool)
  field(:count, 6, type: :bool)
  field(:list, 7, type: :bool)
  field(:upsert, 8, type: :bool)
  field(:lang, 9, type: :bool)
end

defmodule Api.LoginRequest do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          userid: String.t(),
          password: String.t(),
          refresh_token: String.t()
        }
  defstruct [:userid, :password, :refresh_token]

  field(:userid, 1, type: :string)
  field(:password, 2, type: :string)
  field(:refresh_token, 3, type: :string)
end

defmodule Api.Jwt do
  @moduledoc false
  use Protobuf, syntax: :proto3

  @type t :: %__MODULE__{
          access_jwt: String.t(),
          refresh_jwt: String.t()
        }
  defstruct [:access_jwt, :refresh_jwt]

  field(:access_jwt, 1, type: :string)
  field(:refresh_jwt, 2, type: :string)
end

defmodule Api.Dgraph.Service do
  @moduledoc false
  use GRPC.Service, name: "api.Dgraph"

  rpc(:Login, Api.LoginRequest, Api.Response)
  rpc(:Query, Api.Request, Api.Response)
  rpc(:Mutate, Api.Mutation, Api.Assigned)
  rpc(:Alter, Api.Operation, Api.Payload)
  rpc(:CommitOrAbort, Api.TxnContext, Api.TxnContext)
  rpc(:CheckVersion, Api.Check, Api.Version)
end

defmodule Api.Dgraph.Stub do
  @moduledoc false
  use GRPC.Stub, service: Api.Dgraph.Service
end
