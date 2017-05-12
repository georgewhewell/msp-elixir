defmodule MSP.Const do
  values = [
    msp_api_version: 1,
    msp_fc_variant:  2,
    msp_fc_version: 3,
    msp_board_info: 4,
    msp_build_info: 5,

    msp_name: 10,
    msp_set_name: 11,

    msp_battery_config: 32,
    msp_set_battery_config: 33,

    msp_ident:  100,
    msp_status: 101,
    msp_raw_gps: 106,
    msp_attitude: 108,
    msp_status_ex: 150,
  ]
  require Logger

  # Lookup header codes
  def decode(value)
  for {key, value} <- values do
    def encode(unquote(key)),   do: unquote(value)
    def decode(unquote(value)), do: unquote(key)
  end
  def decode(unknown_code), do: unknown_code
  def decode(c, data), do: unpack(decode(c), data)

  def unpack(:msp_api_version, <<
    >>) do
      {:msp_api_version, %{}}
    end

  def unpack(:msp_ident,
    <<
      version     :: integer-size(8),
      multitype   :: integer-size(8),
      msp_version :: integer-size(8),
      capability  :: integer-size(32),
    >>) do
      {:msp_ident, %{version: version, multitype: multitype, msp_version: msp_version, capability: capability}}
  end

  def unpack(:msp_status,
    <<
    cycleTime::     integer-size(16),
    i2cErrorCount:: integer-size(16),
    sensor::        integer-size(16),
    flags::         binary-size(4),
    currentSet::    integer-size(8),
    >>) do
      {:msp_status, %{cycleTime: cycleTime, i2cErrorCount: i2cErrorCount, sensor: sensor, flags: flags, currentSet: currentSet}}
    end

  def unpack(:msp_status_ex,
    <<
      cycleTime::     integer-size(16),
      i2cErrorCount:: integer-size(16),
      sensor::        integer-size(16),
      flags::         binary-size(4),
      currentSet::    integer-size(8),
      load::          integer-size(16),
      maxProfiles::   integer-size(8),
      currentRateProfile:: integer-size(8),
    >>) do
    {:msp_status_ex, %{cycleTime: cycleTime, i2cErrorCount: i2cErrorCount, sensor: sensor, flags: flags, currentSet: currentSet, load: load, maxProfiles: maxProfiles, currentRateProfile: currentRateProfile}}
  end

  def pack(:msg_id, %{a1: a1, a2: a2}), do: << data.a1, data.a2 >>
  def unpack(:msg_id, << a1::integer-size(8), a2::integer-size(8)), do: %{a1: a1, a2: a2}


  def unpack(code, data), do: {code, data}
end
