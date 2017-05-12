defmodule FramingTest do
  use ExUnit.Case
  alias MSP.Framing

  test "adds framing" do
      {:ok, buffer} = Framing.init()
      assert {:error, <<>>, ^buffer} = Framing.add_framing("", buffer)
      assert {:ok, <<"$M<", 0, 101, 101>>, ^buffer} = Framing.add_framing("e", buffer)
      assert {:ok, <<"$M<", 3, "X", "A","B","C", _>>, ^buffer} = Framing.add_framing("XABC", buffer)
  end

  test "removes framing" do
    {:ok, buffer} = Framing.init()
    assert {:ok, [{0, ""}], ^buffer} = Framing.remove_framing(<<"$M>",0,0,0>>, buffer)
    assert {:ok, [{3, "666"}], ^buffer} = Framing.remove_framing(<<"$M>",3,3,54,54,54,54>>, buffer)
    assert {:ok, [{0, "ABC"}, {0,"DEF"}], ^buffer} = Framing.remove_framing(<<"$M>", 3, 0, "ABCC", "$M>", 3, 0, "DEFD">>, buffer)
  end

  test "handles partial lines" do
    {:ok, buffer} = Framing.init()

    assert {:ok, [], buffer} = Framing.remove_framing(<<"$M>", 3, 0, "ABC">>, buffer)
    assert {:ok, [{0, "ABC"}], buffer} = Framing.remove_framing(<<"C">>, buffer)

    assert {:ok, [], buffer} = Framing.remove_framing(<<"DEF$M>", 3, 0, "GHI">>, buffer)
    assert {:ok, [{0,"GHI"}], buffer} = Framing.remove_framing("E", buffer)

    assert buffer == <<>>
  end

  test "checksum must be valid" do
    {:ok, buffer} = Framing.init()
    assert {:ok, [{:echksum, _}, {1, ""}], ^buffer} = Framing.remove_framing(<<"$M>",0,1,0,"$M>",0,1,1>>, buffer)
  end

  test "clears framing buffer on flush" do
    {:ok, buffer} = Framing.init()

    assert {:ok, [], buffer} = Framing.remove_framing(<<"$M>", 4, "ABC">>, buffer)
    assert buffer == <<"$M>",4,"ABC">>

    buffer = Framing.flush(:receive, buffer)
    assert buffer == <<>>
  end

  test "preamble fragmentation" do
    {:ok, buffer} = Framing.init()

    assert {:ok, [], buffer} = Framing.remove_framing(<<"$">>, buffer)
    assert buffer == "$"

    assert {:ok, [], buffer} = Framing.remove_framing(<<"M">>, buffer)
    assert buffer == "$M"

    assert {:ok, [], buffer} = Framing.remove_framing(<<">">>, buffer)
    assert buffer == "$M>"

    assert {:ok, [{0, ""}], buffer} = Framing.remove_framing(<<0,0,0>>, buffer)
    assert buffer == <<>>
  end

  test "can use tuple syntax" do
    {:ok, buffer} = Framing.init()
    assert {:ok, framedata, ^buffer} = Framing.add_framing(:msp_status, buffer)
    assert {:ok, [{:msp_status, ""}], ^buffer} = Framing.remove_framing(framedata)
  end
end
