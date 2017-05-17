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

  test "msp_build_info" do
    assert Codec.unpack(<<5, "Apr 22 2017", "14:55:51", "4328b13">>) == \
      {:ok, {:msp_build_info, %{build_date: "Apr 22 2017", build_time: "14:55:51", git_revision: "4328b13"}}}
  end

  test "msp_name" do
    assert Codec.unpack(<<10, "ABC">>) == \
      {:ok, {:msp_name, "ABC"}}
  end

end
