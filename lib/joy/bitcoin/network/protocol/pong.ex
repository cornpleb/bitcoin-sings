defmodule Joy.Bitcoin.Network.Protocol.Pong do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#pong

  The pong message is sent in response to a ping message. In modern protocol
  versions, a pong response is generated using a nonce included in the ping.

  Payload:

  Field Size 	Description 	Data type 	Comments
  8 	        nonce 	      uint64_t 	  nonce from ping
  """
  defstruct nonce: 0

  alias Joy.Bitcoin.Network.Protocol.Pong

  def parse(<<nonce::binary-size(8), rest::binary>>) do
    {:ok, %Pong{nonce: nonce}, rest}
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Pong do
  def serialize(pong) do
    <<pong.nonce::binary-size(8)>>
  end
end
