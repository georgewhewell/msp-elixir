defmodule MSP.Codec do

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
    {10, :msp_name, :binary},
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
      {:currentSetting, :unsigned, 8},
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
  ]

  defmodule Patterns do

    # Handle single field, variable length response
    def binary(code, :binary) do
      {:<<>>, [], [code] ++ [{:::, [], [{:data, [], __MODULE__}, {:binary, [], __MODULE__}]}]}
    end
    def map(:binary), do: {:data, [], __MODULE__}

    # Handle bit-packed data
    def binary(code, bits) do
      {:<<>>, [], [code] ++ Enum.map(bits, fn {name, type, length} ->
        {:::, [], [
          {name, [], __MODULE__},
          {:-, [], [
            {type, [], __MODULE__},
            {:size, [], [length]}]
          }
        ]}
      end)}
    end

    def map(bits) do
      {:%{}, [], Enum.map(bits, fn {name, _, _} ->
        {name, {name, [], __MODULE__}}
      end)}
    end
  end

  for {code, cmd, bits} <- commands do
    def unpack(binary)
    def unpack(unquote(Patterns.binary(code, bits))) do
      {:ok, {unquote(cmd), unquote(Patterns.map(bits))}}
    end
    def unpack(<<unquote(code), rest::binary>>) do
      {:error, {unquote(cmd), rest}}
    end

    def pack(unquote(cmd), unquote(Patterns.map(bits))) do
      unquote(<<code>>) <> unquote(Patterns.binary(code, bits))
    end

    def pack(unquote(cmd), %{}) do
      unquote(<<code>>)
    end
  end
end
