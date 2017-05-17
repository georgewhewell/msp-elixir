defmodule MacroTest do
  use ExUnit.Case
  alias MSP.Codec.Patterns

  @simple [{:version, :unsigned, 8}]

  test "map syntax" do
    assert Patterns.map(@simple) == quote do: %{version: version}
  end

  test "binary syntax" do
    assert Patterns.binary(100, @simple) == quote do: <<100, version::unsigned-size(8)>>
  end

  test "variable length" do
    assert Patterns.binary(100, :binary) == quote do: <<100, data::binary>>
  end
end
