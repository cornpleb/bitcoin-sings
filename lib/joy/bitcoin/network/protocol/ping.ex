defmodule Joy.Bitcoin.Network.Protocol.Ping do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#ping

  The ping message is sent primarily to confirm that the TCP/IP connection is
  still valid. An error in transmission is presumed to be a closed connection
  and the address is removed as a current peer.

  Payload:

  Field Size 	Description 	Data type 	Comments
  8 	        nonce 	      uint64_t 	  random nonce
  """

  defstruct nonce: 0

  alias Joy.Bitcoin.Network.Protocol.Ping

  def parse(<<nonce::binary-size(8), rest::binary>>) do
    {:ok, %Ping{nonce: nonce}, rest}
  end

  def parse(<<>>) do
    {:ok, %Ping{}, <<>>}
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Ping do
  def serialize(ping) do
    <<ping.nonce::binary-size(8)>>
  end
end
