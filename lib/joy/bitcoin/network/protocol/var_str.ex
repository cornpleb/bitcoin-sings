defmodule Joy.Bitcoin.Network.Protocol.VarStr do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#Variable_length_string

  Variable length string can be stored using a variable length integer followed
  by the string itself.

  Field Size 	Description 	Data type 	Comments
  1+ 	        length 	      var_int 	  Length of the string
  ? 	        string 	      char[] 	    The string itself (can be empty)
  """

  defstruct value: nil

  alias Joy.Bitcoin.Network.Protocol.VarInt
  alias Joy.Bitcoin.Network.Protocol.VarStr

  def parse(binary) do
    with {:ok, %VarInt{value: length}, rest} <- VarInt.parse(binary),
         <<value::binary-size(length), rest::binary>> <- rest do
      {:ok, %VarStr{value: value}, rest}
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.VarStr do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.VarInt
  alias Joy.Bitcoin.Network.Protocol.VarStr

  def serialize(%VarStr{value: value}) do
    <<Protocol.serialize(%VarInt{value: String.length(value)})::binary, value::binary>>
  end
end
