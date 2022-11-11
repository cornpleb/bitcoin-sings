defmodule Joy.Bitcoin.Network.Protocol.Inv do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#inv

  Allows a node to advertise its knowledge of one or more objects. It can be
  received unsolicited, or in reply to getblocks.

  Payload (maximum 50,000 entries, which is just over 1.8 megabytes):

  Field Size 	 Description 	  Data type 	  Comments
  1+ 	         count 	        var_int 	    Number of inventory entries
  36x? 	       inventory 	    inv_vect[] 	  Inventory vectors
  """

  defstruct count: nil, inventory: nil

  alias Joy.Bitcoin.Network.Protocol.{Inv, InvVect, VarInt}

  def parse(binary) do
    case VarInt.parse(binary) do
      {:ok, %VarInt{value: count}, rest} ->
        {:ok,
         %Inv{
           count: count,
           inventory:
             for <<binary::binary-size(36) <- rest>> do
               {:ok, inv_vect, _rest} = InvVect.parse(binary)
               inv_vect
             end
         }, <<>>}
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Inv do
  def serialize(_inv) do
    <<>>
  end
end
