defmodule Joy.Bitcoin.Network.Protocol.GetData do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#getdata

  getdata is used in response to inv, to retrieve the content of a specific
  object, and is usually sent after receiving an inv packet, after filtering
  known elements. It can be used to retrieve transactions, but only if they
  are in the memory pool or relay set - arbitrary access to transactions in
  the chain is not allowed to avoid having clients start to depend on nodes
  having full transaction indexes (which modern nodes do not).

  Payload (maximum 50,000 entries, which is just over 1.8 megabytes):

  Field Size 	Description 	Data type 	  Comments
  1+ 	        count 	      var_int 	    Number of inventory entries
  36x? 	      inventory 	  inv_vect[] 	  Inventory vectors
  """

  defstruct count: nil, inventory: nil

  alias Joy.Bitcoin.Network.Protocol.GetData

  def parse(<<>>) do
    {:ok, %GetData{}, <<>>}
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.GetData do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.{GetData, VarInt}

  def serialize(%GetData{count: count, inventory: inventory}) do
    <<
      Protocol.serialize(%VarInt{value: count})::binary,
      Enum.map_join(inventory, &Protocol.serialize/1)::binary
    >>
  end
end
