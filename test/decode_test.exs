defmodule DecodeTest do
  use ExUnit.Case
  alias MSP.Codec

  test "msp_api_version" do
    assert Codec.unpack(<<1, 1, 2, 3>>) == \
      {:ok, {:msp_api_version, %{msp_protocol_version: 1, api_version_major: 2, api_version_minor: 3}}}
  end

  test "msp_fc_variant" do
    assert Codec.unpack(<<2, "CLFL">>) == \
      {:ok, {:msp_fc_variant, %{fc_identifier: "CLFL"}}}
  end

  test "msp_fc_version" do
    assert Codec.unpack(<<3, 1, 2, 3>>) == \
      {:ok, {:msp_fc_version,  %{fc_version_major: 1, fc_version_minor: 2, fc_version_patch: 3}}}
  end

  test "msp_board_info" do
    assert Codec.unpack(<<4, "SPEV", 0, 0, 0>>) == \
      {:ok, {:msp_board_info, %{board_identifier: "SPEV", board_type: 0, hardware_revision: 0}}}
  end


end
