defmodule MSP.Framing do
  use Bitwise, skip_operators: true
  @behaviour Nerves.UART.Framing

  # detect start of MSP message
  @preamble_recv   "$M>"
  @preamble_send   "$M<"

  # for detector skip
  @preamble_len     byte_size(@preamble_recv)

  def init(_args \\ []), do: {:ok, <<>>}
  def frame_timeout(_state), do: {:ok, [], <<>>}
  def flush(_direction, _state), do: <<>>

  #   MSP frame
  #               |<---- C ---->|
  #   1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
  #   H | H | D | L | T | M | M | C
  #
  #  HH  Header, always "$","M"
  #  D   Direction- 1 byte, either send "<" or receive ">"
  #  L   Length- 1 byte UINT, length of message
  #  T   Type- 1 byte, MSP command (see Const.)
  #  M+  Message- 0+ bytes, message body
  #  C   Checksum- 1 byte, recursive XOR of L, T and each byte of M
  #

  # Add MSP frame to message
  def add_framing(<<type::integer-size(8), message::binary>>, _state) do
    payload = <<byte_size(message), type>> <> message
    {:ok, @preamble_send <> payload <> <<crc(payload)>>, _state}
  end
  def add_framing(_, buffer), do: {:error, <<>>, buffer}

  # Checksum is recursive XOR of payload
  def crc(bin, acc \\ 0)
  def crc(<<>>, acc), do: acc
  def crc(<<head, data::binary>>, acc), do: bxor(head, crc(data, acc))

  # Return translated message or error
  defp build_msg(type, data, check) do
    case crc(<<byte_size(data)>> <> type <> data) do
      ^check -> {type, data}
      else_  -> {:echksum, {type, else_}}
    end
  end

  # Append new data to buffer and advance pointer, returning any new messages
  def remove_framing(new_data, buffer) do
    {msgs, buffer} = process_data([], buffer <> new_data)
    {:ok, msgs, buffer}
  end

  # Not enough data to begin detecting, skip
  defp process_data(msgs, buffer) when byte_size(buffer) <= @preamble_len, do: {msgs, buffer}

  # Header matches..
  defp process_data(msgs, buffer = <<@preamble_recv, len::integer-size(8), frame_data::binary>>) do
    case frame_data do
      # Full message (+rest)-
      << type   ::   binary-size(1),
         data   ::   binary-size(len),
         check  ::   integer-size(8),
         rest   ::   binary  >> ->
           new_msg = build_msg(type, data, check)
           process_data(msgs ++ [new_msg], rest)
      # Not enough data, skip
      << _else::binary >> -> {msgs, buffer}
    end
  end

  # Header didnt match (but we have enough data for a frame), eat a character :)
  defp process_data(msgs, <<_, rest::binary>>), do: process_data(msgs, rest)

end
