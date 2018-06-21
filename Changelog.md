# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0-alpha.4] - 2018-06-21
### Added
- New function `set_struct/2`. This function allow you to convert an struct type into a mutation (json based) type in dgraph. It also allows you to enforce the schema in database (adding a "class name" info before every predicate, this class name is the single name given to the elixir module struct) by activating the `enforce_struct_schema` in the config files. The function sends the mutation to the server and returns `{:ok, result}` or `{:error, error}` otherwise. Internally it uses Dgraphs `set_json`. Thanks to @WolfDan.
- New config option `keepalive`. It defines the time in ms between pings to the server. Default value is `:infinity` which disables pings completely. Dgraph drops the connection on pings at the moment so it is disabled for now. Internally this uses `:adapter_opts` of grpc-elixir which in turn sets `http2_opts` of gun.
- I added a changelog.

## Fixed
- The `keepalive` option fixes the `gun_down` error for now. The connection was dropped by Dgraph when the server was pinged. The server sent a `{goaway,0,enhance_your_calm,<<"too_many_pings">>}` message. For now pings are disabled. This is not ideal since this way ExDgraph cannot check if the connection is still alive. But I have to wait for Dgraph to get back to me on this issue. You find the issue here: https://github.com/dgraph-io/dgraph/issues/2444
