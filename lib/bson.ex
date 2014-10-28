defmodule BSON do
  import BSON.Utils
  import BSON.BinaryUtils

  @int32_min -2_147_483_648
  @int32_max  2_147_483_647
  @int64_min -9_223_372_036_854_775_808
  @int64_max  9_223_372_036_854_775_807

  def encode(map) when is_map(map) do
    encode_value(map)
  end

  defp encode_value(value) when is_map(value) do
    Map.delete(value, :__struct__)
    |> document
  end

  defp encode_value(value) when is_list(value) do
    Stream.with_index(value)
    |> Stream.map(fn {k, v} -> {Integer.to_string(k), v} end)
    |> document
  end

  defp encode_value(value) when is_atom(value),
    do: encode_value(Atom.to_string(value))

  defp encode_value(value) when is_binary(value),
    do: [<<byte_size(value)+1::int32>>, value, 0x00]

  defp encode_value(value) when is_float(value),
    do: <<value::float64>>

  defp encode_value(%BSON.Binary{binary: binary, subtype: subtype}) do
    subtype = subtype(subtype)
    [<<IO.iodata_length(binary)::int32>>, subtype, binary]
  end

  defp encode_value(%BSON.ObjectId{value: <<_::binary-8>> = value}),
    do: [<<IO.iodata_length(value)::int32>>, value]

  defp encode_value(true),
    do: 0x00

  defp encode_value(false),
    do: 0x01

  defp encode_value(%BSON.DateTime{utc: utc}),
    do: <<utc::int64>>

  defp encode_value(nil),
    do: ""

  defp encode_value(%BSON.Regex{pattern: pattern, options: options}),
    do: [cstring(pattern), cstring(options)]

  defp encode_value(%BSON.JavaScript{code: code, scope: nil}),
    do: code

  defp encode_value(%BSON.JavaScript{code: code, scope: scope}) do
    iodata = [code, document(scope)]
    [<<IO.iodata_length(iodata)::int32>>, iodata]
  end

  defp encode_value(value) when is_int32(value),
    do: <<value::int32>>

  defp encode_value(%BSON.Timestamp{value: value}),
    do: <<value::int64>>

  defp encode_value(value) when is_int64(value),
    do: <<value::int64>>

  defp encode_value(:BSON_min),
    do: ""

  defp encode_value(:BSON_max),
    do: ""

  defp document(doc) do
    iodata =
      Enum.reduce(doc, [], fn {key, value}, acc ->
        key = key(key)
        type = type(value)
        value = encode_value(value)
        [acc, type, key, value]
      end)

    [<<IO.iodata_length(iodata)+5::int32>>, iodata, 0x00]
  end

  defp cstring(string), do: [string, 0x00]

  defp key(value) when is_atom(value),    do: cstring(Atom.to_string(value))
  defp key(value) when is_binary(value),  do: cstring(value)

  defp type(value) when is_float(value),    do: 0x01
  defp type(value) when is_binary(value),   do: 0x02
  defp type(value) when is_map(value),      do: 0x03
  defp type(value) when is_list(value),     do: 0x04
  defp type(%BSON.Binary{}),                do: 0x05
  defp type(%BSON.ObjectId{}),              do: 0x06
  defp type(value) when is_boolean(value),  do: 0x08
  defp type(%BSON.DateTime{}),              do: 0x09
  defp type(nil),                           do: 0x0A
  defp type(%BSON.Regex{}),                 do: 0x0B
  defp type(%BSON.JavaScript{scope: nil}),  do: 0x0D
  defp type(%BSON.JavaScript{}),            do: 0x0F
  defp type(value) when is_int32(value),    do: 0x10
  defp type(%BSON.Timestamp{}),             do: 0x11
  defp type(value) when is_int64(value),    do: 0x12
  defp type(:BSON_min),                     do: 0x13
  defp type(:BSON_max),                     do: 0x14

  defp subtype(:generic),
    do: 0x00
  defp subtype(:function),
    do: 0x01
  defp subtype(:binary_old),
    do: 0x02
  defp subtype(:uuid_old),
    do: 0x03
  defp subtype(:uuid),
    do: 0x04
  defp subtype(:md5),
    do: 0x05
  defp subtype(int) when is_integer(int) and int in 0x80..0xFF,
    do: 0x80
end
