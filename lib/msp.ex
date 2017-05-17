defmodule MSP.Client do
  alias MSP.Codec
  @moduledoc """
  Documentation for MSP.
  """

  @doc """
  Hello world.

  ## Examples

      iex> MSP.hello
      :world
      msp_api_version: 1,
      msp_fc_variant:  2,
      msp_fc_version: 3,
      msp_board_info: 4,
      msp_build_info: 5,
  """
  defmodule State do
    defstruct [
      nerves_uart: nil,
      connected: false,
      identified: false,
    ]
  end

  use GenServer
  require Logger

  def start_link(port \\ "ttyACM0", opts \\ []) do
    Logger.debug "#{__MODULE__} Starting"
    GenServer.start_link(__MODULE__, port, opts)
  end

  def init(port) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, port, speed: 115200, active: true, framing: MSP.Framing)
    send_request(pid, :msp_ident)
    send_request(pid, :msp_api_version)
    send_request(pid, :msp_fc_variant)
    send_request(pid, :msp_fc_version)
    send_request(pid, :msp_board_info)
    # send_request(pid, :msp_status_ex)
    # send_request(pid, :msp_status)
    # send_request(pid, :msp_status_ex)
    # send_request(pid, :msp_api_version)
    # send_request(pid, :msp_fc_variant)
    # send_request(pid, :msp_fc_version)
    # send_request(pid, :msp_fc_variant)
    # send_request(pid, :msp_board_info)
    # send_request(pid, :msp_build_info)
    {:ok, %State{nerves_uart: pid}}
  end

  # def encode(type, msg) when is_atom(type), do: <<Const.encode(type)>> <> msg
  # def encode(type, msg), do: type <> msg
  def send_request(pid, type, msg \\ %{}), do: write(pid, {type, msg})

  def write(pid, {type, msg}), do: Nerves.UART.write(pid, Codec.pack(type, msg))

  # def decode(<<type::integer-size(8), message::binary>>), do: {:ok, {Const.decode(type), message}}
  # def decode(_else), do: {:error, "Bad Message!"}

  def handle_info({:nerves_uart, "ttyACM0", {:ok, data}}, state) do
    {code, payload} = Codec.unpack(data)
    Logger.debug "Got data: #{inspect code}, data is #{inspect payload}"
    case handle({code, payload}, state) do
      {:ok, state} ->
        {:noreply, state}
      {:error, state} ->
        {:noreply, state}
    end
  end

  def handle({type, data}, state) do
    Logger.debug "Discarding unhandled message type: #{type} data: #{inspect data}"
    {:error, state}
  end
end
