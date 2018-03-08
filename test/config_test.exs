defmodule Config.Test do
  use ExUnit.Case
  alias ExDgraph.Utils

  @basic_config [
    hostname: 'ole',
    port: 1234,
    pool_size: 10,
    max_overflow: 7
  ]

  test "standard ExDgraph configuration parameters" do
    config = Utils.default_config(@basic_config)

    assert config[:hostname] == 'ole'
    assert config[:port] == 1234
    assert config[:pool_size] == 10
    assert config[:max_overflow] == 7
  end

  test "standard ExDgraph default configuration" do
    config = Utils.default_config([])

    assert config[:hostname] == 'localhost'
    assert config[:port] == 9080
  end
end
