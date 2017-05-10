defmodule MSP do
  @moduledoc """
  Documentation for MSP.
  """

  @doc """
  Hello world.

  ## Examples

      iex> MSP.hello
      :world

  """
  defmodule State do
    defstruct [
      nerves_uart: nil,
    ]
  end

  use GenServer
  require Logger
  alias MSP.Const

  def start_link(settings, opts \\ []) do
    Logger.debug "#{__MODULE__} Starting"
    GenServer.start_link(__MODULE__, settings, opts)
  end

  def init(settings) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, "ttyACM0", speed: 115200, active: true, framing: MSP.Framing)
    send_request(pid, :msp_status)
    send_request(pid, :msp_status_ex)
    {:ok, %State{nerves_uart: pid}}
  end

  def encode(type, msg), do: <<Const.encode(type)>> <> msg
  def send_request(pid, type, msg \\ <<>>), do: write(pid, encode(type, msg))

  def write(pid, data), do: Nerves.UART.write(pid, data)

  def decode(<<type::integer-size(8), message::binary>>), do: {:ok, {Const.decode(type), message}}
  def decode(_else), do: {:error, "Bad Message!"}

  def handle_info({:nerves_uart, "ttyACM0", {type, data}}, state) do
    Logger.debug "Got data: #{inspect type}, state is #{inspect state}"
    case handle({type, data}, state) do
      {:ok, state} ->
        {:noreply, state}
      {:error, state} ->
        {:noreply, state}
    end
  end

  def handle(message, state)
  def handle({:msp_status,
    <<
      cycleTime::     integer-size(16),
      i2cErrorCount:: integer-size(16),
      sensor::        integer-size(16),
      flag::          binary-size(4),
      currentSet::    integer-size(8),
    >>}, state) do
    Logger.debug "A message for me!"
    Logger.debug "#{cycleTime} #{i2cErrorCount} #{sensor} #{flag} #{currentSet}"
    {:ok, state}
  end

  def handle({:msp_status_ex, data}, state) do
    Logger.debug "Extended status: #{inspect data}"
    {:ok, state}
  end

  def handle({type, data}, state) do
    Logger.debug "Discarding unhandled message type: #{type} data: #{inspect data}"
    {:error, state}
  end
end
