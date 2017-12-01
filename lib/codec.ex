defmodule MSP.Codec do
  require Logger

  # List of MSP commands.
  commands = [
    {1, :msp_api_version, [
      {:msp_protocol_version, :unsigned, 8},
      {:api_version_major, :unsigned, 8},
      {:api_version_minor, :unsigned, 8},
    ]},
    {2, :msp_fc_variant, [
      {:fc_identifier, :binary, 4},
    ]},
    {3, :msp_fc_version, [
      {:fc_version_major, :unsigned, 8},
      {:fc_version_minor, :unsigned, 8},
      {:fc_version_patch, :unsigned, 8},
    ]},
    {4, :msp_board_info, [
      {:board_identifier, :binary, 4},
      {:hardware_revision, :unsigned, 16},
      {:board_type, :unsigned, 8},
    ]},
    {5, :msp_build_info, [
      {:build_date, :binary, 11},
      {:build_time, :binary, 8},
      {:git_revision, :binary, 7},
    ]},
    # {10, :msp_name, :binary}, # special case
    # {11, :msp_set_name, :binary}, # special case
    {32, :msp_battery_config, [
      {:vbatmincellvoltage, :unsigned, 8},
      {:vbatmaxcellvoltage, :unsigned, 8},
      {:vbatwarningcellvoltage, :unsigned, 8},
      {:batteryCapacity, :unsigned, 16},
      {:voltageMeterSource, :unsigned, 8},
      {:currentMeterSource, :unsigned, 8},
    ]},
    {33, :msp_set_battery_config, []},
    {34, :msp_mode_ranges, [
        {:data, :binary, 80},
    ]},
    {35, :msp_set_mode_range, []},
    {36, :msp_feature_config, []},
    {37, :msp_set_feature_config, []},
    {38, :msp_board_alignment_config, [
        {:roll, :signed, 16},
        {:pitch, :signed, 16},
        {:yaw, :signed, 16},
    ]},
    {39, :msp_set_board_alignment_config, []},
    {100, :msp_ident, [
      {:version, :unsigned, 8},
      {:multitype, :unsigned, 8},
      {:msp_version, :unsigned, 8},
      {:capability, :unsigned, 32},
    ]},
    {101, :msp_status, [
      {:cycleTime, :unsigned, 16},
      {:i2c_errors_count, :unsigned, 16},
      {:sensor, :unsigned, 16},
      {:flag, :unsigned, 32},
      {:currentSet, :unsigned, 8},
      {:load, :unsigned, 16},
      {:gyroCycleTime, :unsigned, 16},
    ]},
    {102, :msp_raw_imu, [
      {:accx, :signed, 16},
      {:accy, :signed, 16},
      {:accz, :signed, 16},
      {:gyrx, :signed, 16},
      {:gyry, :signed, 16},
      {:gyrz, :signed, 16},
      {:magx, :signed, 16},
      {:magy, :signed, 16},
      {:magz, :signed, 16},
    ]},
    # {103, :msp_servo, :binary}, # unimplemented- list case
    # {104, :msp_rc, :binary}, # unimplemented- list case
    {104, :msp_motor, [
      {:motor0, :unsigned, 16},
      {:motor1, :unsigned, 16},
      {:motor2, :unsigned, 16},
      {:motor3, :unsigned, 16},
      {:motor4, :unsigned, 16},
      {:motor5, :unsigned, 16},
      {:motor6, :unsigned, 16},
      {:motor7, :unsigned, 16},
    ]},
    {106, :msp_raw_gps, [
      {:motor0, :unsigned, 16},
      {:motor1, :unsigned, 16},
      {:motor2, :unsigned, 16},
      {:motor3, :unsigned, 16},
      {:motor4, :unsigned, 16},
      {:motor5, :unsigned, 16},
      {:motor6, :unsigned, 16},
      {:motor7, :unsigned, 16},
    ]},
    {107, :msp_comp_gps, [
      {:distance, :unsigned, 16},
      {:direction, :unsigned, 16},
    ]},
    {108, :msp_attitude, [
      {:roll, :unsigned, 16},
      {:pitch, :unsigned, 16},
      {:yaw, :unsigned, 16},
    ]},
    {109, :msp_altitude, [
      {:estimatedAltitude, :unsigned, 32},
      {:estimatedVario, :unsigned, 16},
    ]},
    {110, :msp_analog, [
      {:batteryVoltage, :unsigned, 8},
      {:mAhDrawn, :unsigned, 16},
      {:rssi, :unsigned, 16},
      {:amperage, :unsigned, 16},
    ]},
    #MSP_RC_TUNING
    # {112, :msp_pid, :binary}, # unimplemented
    {164, :msp_gpssvinfo, [
      {:batteryVoltage, :unsigned, 8},
      {:mAhDrawn, :unsigned, 16},
      {:rssi, :unsigned, 16},
      {:amperage, :unsigned, 16},
    ]},
    {166, :msp_gpsstatistics, [
      {:batteryVoltage, :unsigned, 8},
      {:mAhDrawn, :unsigned, 16},
      {:rssi, :unsigned, 16},
      {:amperage, :unsigned, 16},
    ]},
  ]

  defmodule Patterns do
    # Module provides functions which given one of the above declarations,
    # returns a pattern-match which can be unquote'ed to define a function which
    # handles this response. retrospect: bad idea
    def binary_match(_code, _bits)
    def binary_match(code, :binary) do
      Logger.info "Creating thing: #{code}"
      {:<<>>, [], [code] ++ [{:::, [], [{:data, [], __MODULE__}, {:binary, [], __MODULE__}]}]}
    end
    def binary_match(code, bits) do
      """
      Return syntax which unquote's to <<code :: integer(8), field :: binary>>
      """
      pmatch = {:<<>>, [],
        [code] ++ Enum.map(bits, fn {name, type, length} ->
          {:::, [], [
            {name, [], __MODULE__},
            {:-, [], [
              {type, [], __MODULE__},
              {:size, [], [length]}]
            }
          ]}
      end)}
      Logger.info "Create pmatch for #{code}: #{inspect pmatch}"
      pmatch
    end

    # Return something like %{ field => value }, and return a function which
    # ?????
    def map_match(_bits)
    def map_match(:binary), do: {:data, [], __MODULE__}
    def map_match(bits) do
      {:%{}, [], Enum.map(bits, fn {name, _, _} ->
        {name, {name, [], __MODULE__}}
      end)}
    end
  end

  # Name is variable-length field
  def pack(:msp_name, %{}), do: <<10>>
  def unpack(<<10, name :: binary>>), do: {:ok, {:msp_name, name}}
  def pack(:msp_set_name, name), do: <<11>> <> name
  def unpack(<<11, name :: binary>>), do: {:ok, {:msp_set_name, name}}

  # Set
  def pack(:msp_name, %{}), do: <<10>>
  def unpack(<<10, name :: binary>>), do: {:ok, {:msp_name, name}}

  def pack(:msp_set_raw_rc, channels), do: <<200>> <> channels
  def unpack(<<200>>), do: {:ok, {:msp_set_rc_raw, nil}}

  # Import-time: for each `command`, create pack/unpack functions
  for {code, cmd, bits} <- commands do
    Logger.info "Creating definitions for #{cmd} (#{code})"

    def unpack(_binary)
    def unpack(unquote(Patterns.binary_match(code, bits))) do
      Logger.error "Did unpack!!!"
      {:ok, {unquote(cmd), unquote(Patterns.map_match(bits))}}
    end
    def unpack(<<unquote(code), rest::binary>>) do
      Logger.error "Wtf, match failed! code: #{unquote code}: length: #{String.length rest}"

      {:error, {unquote(cmd), rest}}
    end

    def pack(_cmd, _data)
    def pack(unquote(cmd), unquote(Patterns.map_match(bits))) do
      # Logger.error "Packing CMD: #{inspect unquote(cmd)}, BITS: #{unquote(bits)}"
      Logger.error "WTF, PACKING #{unquote(cmd)}, #{inspect unquote(Patterns.map_match(bits))}"
      what = unquote(Patterns.binary_match(code, bits))
      Logger.error "response is #{inspect what <> <<0>>}"
      what
    end

    def pack(unquote(cmd), %{}) do
      unquote(<<code>>)
    end
  end
end
