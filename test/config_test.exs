defmodule Config.Test do
  use ExUnit.Case, async: true
  alias ExDgraph.Utils

  @basic_config [
    hostname: 'ole',
    port: 1234,
    pool_size: 10,
    max_overflow: 7
  ]

  @ssl_config [
    ssl: true,
    cacertfile: "MyRootCA.pem"
  ]

  test "standard ExDgraph configuration parameters" do
    config = Utils.default_config(@basic_config)

    assert config[:hostname] == 'ole'
    assert config[:port] == 1234
    assert config[:pool_size] == 10
    assert config[:max_overflow] == 7
    assert config[:ssl] == false
    assert config[:tls_client_auth] == false
    assert config[:enforce_struct_schema] == false
    assert config[:keepalive] == :infinity
  end

  test "standard ExDgraph default configuration" do
    config = Utils.default_config([])

    assert config[:hostname] == 'localhost'
    assert config[:port] == 9080
    assert config[:ssl] == false
    assert config[:tls_client_auth] == false
    assert config[:enforce_struct_schema] == false
    assert config[:keepalive] == :infinity
  end

  test "ssl config from parameters" do
    config = Utils.default_config(@ssl_config)

    assert config[:ssl] == true
    assert config[:cacertfile] == "MyRootCA.pem"
  end
end
