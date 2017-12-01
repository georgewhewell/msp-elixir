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
      state: %{},
      stack: %{},
    ]
  end

  use GenServer
  require Logger

  def start_link(port \\ "/dev/ttyACM0", opts \\ []) do
    Logger.debug "#{__MODULE__} Starting agent for: #{port} (#{inspect opts})"
    GenServer.start_link(__MODULE__, port, opts)
  end

  def init(port) do
    {:ok, pid} = Nerves.UART.start_link
    Logger.debug "#{__MODULE__} Opening UART"
    :ok = Nerves.UART.open(pid, port, speed: 115200, active: true, framing: MSP.Framing)
    Logger.debug "#{__MODULE__} Great! Uart Open"
    send_message(pid, :msp_ident)
    # send_message(pid, :msp_board_alignment_config)
    # send_message(pid, :msp_feature_config)
    # send_message(pid, :msp_mode_ranges)
    # send_message(pid, :msp_battery_config)
    send_message(pid, :msp_name)
    send_message(pid, :msp_set_name, "FUCKUP") # doesnt work?
    send_message(pid, :msp_name)


    # send_request(pid, :msp_status_ex)
    # send_message(pid, :msp_status)
    # send_request(pid, :msp_status_ex)
    # send_message(pid, :msp_api_version)
    # send_request(pid, :msp_fc_variant)
    # send_request(pid, :msp_fc_version)
    # send_message(pid, :msp_fc_variant)
    # send_message(pid, :msp_board_info)
    # send_message(pid, :msp_build_info)
    # send_message(pid, :msp_raw_imu)
    # send_message(pid, :msp_motor)
    # send_message(pid, :msp_raw_gps) # no reply?
    send_message(pid, :msp_comp_gps) # no reply?
    # send_message(pid, :msp_attitude)
    # send_message(pid, :msp_altitude)
    # send_message(pid, :msp_analog) # no reply?
    send_message(pid, :msp_gpssvinfo)
    send_message(pid, :msp_gpsstatistics)
    send_message(pid, :msp_set_raw_rc, <<0, 0, 0, 0>>)

    {:ok, %State{nerves_uart: pid}}
  end

  def send_message(pid, type, msg \\ %{}) do
    Logger.debug "#{__MODULE__} Sending message: #{inspect {type, msg}}"
    Nerves.UART.write(pid, Codec.pack(type, msg))
  end

  def handle_info({:nerves_uart, _port, {:ok, data}}, state) do
    {:ok, {code, payload}} = Codec.unpack(data)
    Logger.debug "Got data: #{inspect code}, data is #{inspect payload}"
    case handle({code, payload}, state) do
      {:ok, state} ->
        {:noreply, state}
      {:error, state} ->
        {:noreply, state}
    end
  end

  def handle_info({:nerves_uart, port, {:echksum, data}}, state) do
    Logger.debug "Message checksum failed! Decoding anyway.."
    handle_info({:nerves_uart, port, {:ok, data}}, state)
  end

  def handle({type, data}, state) do
    Logger.debug "Discarding unhandled message type: #{type} data: #{inspect data}"
    {:error, state}
  end

end
