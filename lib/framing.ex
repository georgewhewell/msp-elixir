defmodule MSP.Framing do
  @behaviour Nerves.UART.Framing

  # detect start of MSP message
  @preamble_recv   "$M>"
  @preamble_send   "$M<"

  # for detector skip
  @preamble_len     byte_size(@preamble_recv)

  use Bitwise

  defmodule State do
    defstruct [ buffer: <<>>, ]
  end

  def init(_args \\ []), do: {:ok, %State{}}
  def frame_timeout(_state), do: {:ok, [], %State{}}
  def flush(_direction, _state), do: %State{}

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
  def add_framing(_, _state), do: {:error, <<>>, _state}

  # Checksum is recursive XOR of payload
  def crc(bin, acc \\ 0)
  def crc(<<>>, acc), do: acc
  def crc(<<head, data::binary>>, acc), do: head ^^^ crc(data, acc)

  # Append new data to buffer and advance pointer, returning any new messages
  def remove_framing(data, state) do
    {new_buffer, lines} = process_data(state.buffer <> data, [])
    rc = if new_buffer == <<>>, do: :ok, else: :in_frame
    {lines, %State{buffer: new_buffer}}
  end
  require Logger

  # Not enough data to begin detecting, skip
  defp process_data(buffer, lines) when byte_size(buffer) <= @preamble_len, do: {buffer, lines}

  # Header matches..
  defp process_data(buffer = <<@preamble_recv, len::integer-size(8), rest::binary>>, lines) do
    case rest do
      # Full message (+rest)
      << type   ::   binary-size(1),
         msg    ::   binary-size(len),
         check  ::   integer-size(8),
         rest   ::   binary  >> ->
           case crc(<<len>> <> type <> msg) do
             # Checksum matches, add to accumulator
             ^check -> process_data(rest, lines ++ [type <> msg])

             # Checksum doesnt match, discard message
             _else  -> process_data(rest, lines)
           end
      # Not enough data, skip
      << _else::binary >> -> {buffer, lines}
    end
  end

  # Header didnt match (but we have enough data for a frame), eat a character :)
  defp process_data(<<_, rest::binary>>, lines), do: process_data(rest, lines)

end
