defmodule Joy.Bitcoin.Network.Protocol.Verack do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#verack

  The verack message is sent in reply to version. This message consists of only
  a message header with the command string "verack".
  """
  defstruct []

  alias Joy.Bitcoin.Network.Protocol.Verack

  def parse(<<>>) do
    {:ok, %Verack{}, <<>>}
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.Verack do
  def serialize(_verack) do
    <<>>
  end
end
