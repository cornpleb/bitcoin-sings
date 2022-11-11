defmodule Joy.Bitcoin.Network.Protocol.TxWitness do
  @moduledoc """
  https://en.bitcoin.it/wiki/Protocol_documentation#tx

  The TxWitness structure is used as part of Tx.

  The TxWitness structure consists of a var_int count of witness data
  components, followed by (for each witness data component) a var_int length of
  the component and the raw component data itself.

  https://github.com/bitcoin/bips/blob/master/bip-0144.mediawiki
  Currently, the only witness objects type supported are script witnesses which
  consist of a stack of byte arrays. It is encoded as a var_int item count
  followed by each item encoded as a var_int length followed by a string of
  bytes. Each txin has its own script witness. The number of script witnesses
  is not explicitly encoded as it is implied by txin_count. Empty script
  witnesses are encoded as a zero byte. The order of the script witnesses
  follows the same order as the associated txins.
  """

  alias Joy.Bitcoin.Network.Protocol.{
    TxWitness,
    TxWitnessComponent,
    VarInt
  }

  defstruct count: nil,
            components: nil

  def parse(binary) do
    with {:ok, count, rest} <- parse_count(binary),
         {:ok, components, rest} <- parse_components(rest, count) do
      {:ok, %TxWitness{count: count, components: components}, rest}
    end
  end

  defp parse_count(binary) do
    with {:ok, %VarInt{value: count}, rest} <- VarInt.parse(binary) do
      {:ok, count, rest}
    end
  end

  defp parse_components(binary, count, components \\ [])

  defp parse_components(binary, count, components) when count == 0,
    do: {:ok, components, binary}

  defp parse_components(binary, count, components) do
    with {:ok, component, rest} <- TxWitnessComponent.parse(binary) do
      parse_components(rest, count - 1, components ++ [component])
    end
  end
end

defimpl Joy.Bitcoin.Network.Protocol,
  for: Joy.Bitcoin.Network.Protocol.TxWitness do
  alias Joy.Bitcoin.Network.Protocol
  alias Joy.Bitcoin.Network.Protocol.VarInt

  def serialize(tx),
    do: <<
      serialize_count(tx)::binary,
      serialize_components(tx)::binary
    >>

  defp serialize_count(%{count: count}),
    do: Protocol.serialize(%VarInt{value: count})

  defp serialize_components(%{components: components}),
    do: Enum.map_join(components, &Protocol.serialize/1)
end
