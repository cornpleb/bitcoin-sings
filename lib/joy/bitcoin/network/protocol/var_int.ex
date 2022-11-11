defmodule Joy.Bitcoin.Network.Protocol.VarInt do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#Variable_length_integer

  Integer can be encoded depending on the represented value to save space.
  Variable length integers always precede an array/vector of a type of data that
  may vary in length. Longer numbers are encoded in little endian.

  Value 	        Storage length 	Format
  < 0xFD 	        1 	            uint8_t
  <= 0xFFFF 	    3 	            0xFD followed by the length as uint16_t
  <= 0xFFFF FFFF 	5 	            0xFE followed by the length as uint32_t
  - 	            9 	            0xFF followed by the length as uint64_t

  If you're reading the Satoshi client code (BitcoinQT) it refers to this
  encoding as a "CompactSize". Modern Bitcoin Core also has the VARINT macro
  which implements an even more compact integer for the purpose of local storage
  (which is incompatible with "CompactSize" described here). VARINT is not a
  part of the protocol.
  """

  defstruct value: nil

  alias Joy.Bitcoin.Network.Protocol.VarInt

  def parse(<<0xFD, value::16-little, rest::binary>>) do
    {:ok, %VarInt{value: value}, rest}
  end

  def parse(<<0xFE, value::32-little, rest::binary>>) do
    {:ok, %VarInt{value: value}, rest}
  end

  def parse(<<0xFF, value::64-little, rest::binary>>) do
    {:ok, %VarInt{value: value}, rest}
  end

  def parse(<<value::8-little, rest::binary>>) do
    {:ok, %VarInt{value: value}, rest}
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.VarInt do
  alias Joy.Bitcoin.Network.Protocol.VarInt

  def serialize(%VarInt{value: value}) when value < 0xFD do
    <<value::8-little>>
  end

  def serialize(%VarInt{value: value}) when value < 0xFFFF do
    <<0xFD, value::16-little>>
  end

  def serialize(%VarInt{value: value}) when value < 0xFFFFFFFF do
    <<0xFE, value::32-little>>
  end

  def serialize(%VarInt{value: value}) do
    <<0xFF, value::64-little>>
  end
end
