defmodule FramingTest do
  use ExUnit.Case
  alias MSP.Framing

  test "adds framing" do
      {:ok, state} = Framing.init()
      assert {:error, <<>>, ^state} = Framing.add_framing("", state)
      assert {:ok, <<"$M<", 0, 101, 101>>, ^state} = Framing.add_framing("e", state)
      assert {:ok, <<"$M<", 3, "X", "A","B","C", _>>, ^state} = Framing.add_framing("XABC", state)
  end

  test "removes framing" do
    {:ok, state} = Framing.init()
    assert {[<<0>>], ^state} = Framing.remove_framing(<<"$M>",0,0,0>>, state)
    assert {[<<3,0,0,0>>], ^state} = Framing.remove_framing(<<"$M>",3,3,0,0,0,0>>, state)
    assert {["ABC", "DEF"], ^state} = Framing.remove_framing(<<"$M>", 2, "ABCB$M>", 2, "DEFE">>, state)
  end

  test "handles partial lines" do
    {:ok, state} = Framing.init()

    assert {[], state} = Framing.remove_framing(<<"$M>", 3, 0, "ABC">>, state)
    assert {[<<0, "ABC">>], state} = Framing.remove_framing(<<"C">>, state)

    assert {[], state} = Framing.remove_framing(<<"DEF$M>", 3, 0, "GHI">>, state)
    assert {[<<0,"GHI">>], state} = Framing.remove_framing("E", state)

    assert state.buffer == <<>>
  end

  test "checksum must be valid" do
    {:ok, state} = Framing.init()
    assert {[], ^state} = Framing.remove_framing(<<"$M>",0,1,0>>, state)
    assert {[<<1>>], ^state} = Framing.remove_framing(<<"$M>",0,1,1>>, state)
  end

  test "clears framing buffer on flush" do
    {:ok, state} = Framing.init()

    assert {[], state} = Framing.remove_framing(<<"$M>", 4, "ABC">>, state)
    assert state.buffer == <<"$M>",4,"ABC">>

    state = Framing.flush(:receive, state)
    assert state.buffer == <<>>
  end

  test "preamble fragmentation" do
    {:ok, state} = Framing.init()

    assert {[], state} = Framing.remove_framing(<<"$">>, state)
    assert state.buffer == "$"

    assert {[], state} = Framing.remove_framing(<<"M">>, state)
    assert state.buffer == "$M"

    assert {[], state} = Framing.remove_framing(<<">">>, state)
    assert state.buffer == "$M>"

    assert {[<<0>>], state} = Framing.remove_framing(<<0,0,0>>, state)
    assert state.buffer == <<>>
  end
end
