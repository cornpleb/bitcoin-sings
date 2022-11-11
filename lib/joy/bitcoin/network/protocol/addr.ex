defmodule Joy.Bitcoin.Network.Protocol.Addr do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#addr

  Provide information on known nodes of the network. Non-advertised nodes should
  be forgotten after typically 3 hours

  Payload:

  Field Size 	Description 	Data type 	              Comments
  1+ 	        count 	      var_int 	                Number of address entries
                                                        (max: 1000)
  30x? 	      addr_list 	  (uint32_t + net_addr)[] 	Address of other nodes on
                                                        the network. version
                                                        < 209 will only read the
                                                        first one. The uint32_t
                                                        is a timestamp (see
                                                        note below).

  Note: Starting version 31402, addresses are prefixed with a timestamp. If no
  timestamp is present, the addresses should not be relayed to other peers,
  unless it is indeed confirmed they are up.
  """

  defstruct count: nil, addr_list: nil

  alias Joy.Bitcoin.Network.Protocol.{Addr, NetAddr, VarInt}

  def parse(binary) do
    case VarInt.parse(binary) do
      {:ok, %VarInt{value: count}, rest} ->
        {:ok,
         %Addr{
           count: count,
           addr_list:
             for <<binary::binary-size(30) <- rest>> do
               {:ok, net_addr, _rest} = NetAddr.parse(binary)
               net_addr
             end
         }, <<>>}
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Addr do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.{Addr, VarInt}

  def serialize(%Addr{count: count, addr_list: addr_list}) do
    <<
      Protocol.serialize(%VarInt{value: count})::binary,
      Enum.map_join(addr_list, &Protocol.serialize/1)::binary
    >>
  end
end
