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
  defmodule Const do
    values = [
      msp_ident:  100,
      msp_status: 101,
      msp_raw_gps: 106,
      msp_attitude: 108,
      msp_status_ex: 150,
      unknown: 404,
    ]
    def decode(value)
    for {key, value} <- values do
      def encode(unquote(key)),   do: unquote(value)
      def decode(unquote(value)), do: unquote(key)
    end
    def decode(unknown), do: unknown
  end

  defmodule State do
    defstruct [
      nerves_uart: nil,
    ]
  end

  use GenServer
  require Logger

  def start_link(settings, opts \\ []) do
    Logger.debug "#{__MODULE__} Starting"
    GenServer.start_link(__MODULE__, settings, opts)
  end

  def init(settings) do
    {:ok, pid} = Nerves.UART.start_link
    :ok = Nerves.UART.open(pid, "ttyACM0", speed: 115200, active: true, framing: MSP.Framing)
    :ok = send_request(pid, :msp_status)
    # :ok = send_request(pid, :msp_status_ex)
    Process.send_after(self(), :work, 1000) # In 2 hours
    {:ok, %State{nerves_uart: pid}}
  end

  def encode(type, msg), do: <<Const.encode(type)>> <> msg
  def send_request(pid, type, msg \\ <<>>), do: write(pid, encode(type, msg))

  def write(pid, data), do: Nerves.UART.write(pid, data)

  def decode(<<type::integer-size(8), message::binary>>), do: {:ok, {Const.decode(type), message}}
  def decode(_else), do: {:error, "Bad Message!"}

  def handle_info({:nerves_uart, "ttyACM0", line}, state) do
    Logger.debug "Got data: #{inspect line}, state is #{inspect state}"
    case decode(line) do
      {:ok, {type, msg}} ->
          case handle({type, msg}, state) do
            {:ok, state} ->
              {:noreply, state}
            {:error, state} ->
              {:noreply, state}
          end
      {:error, info} ->
          Logger.debug "It didnt decode. #{inspect info}"
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

  def handle({:msp_status_ex,
    <<
      cycleTime::     integer-size(16),
      i2cErrorCount:: integer-size(16),
      sensor::        integer-size(16),
      flags::         binary-size(4),
      currentSet::    integer-size(8),
      load::          integer-size(16),
      maxProfiles::   integer-size(8),
      currentRateProfile:: integer-size(8),
    >>}, state) do
    Logger.debug "A message for me!"
    Logger.debug "#{cycleTime} #{i2cErrorCount} #{sensor} #{flags} #{currentSet} #{load} #{maxProfiles} #{currentRateProfile}"
    {:ok, state}
  end

  def handle({:msp_status_ex, data}, state) do
    Logger.debug "Extended status: #{inspect data}"
    {:ok, state}
  end

  def handle({type, data}, state) do
    Logger.debug "Discarding unhandled message type: #{type} data: #{data}"
    {:error, state}
  end
end
